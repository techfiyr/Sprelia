import { createLogger } from './common/logger.js';
import { ConfigError, loadConfig } from './config/env.js';
import { credentialSource } from './firebase/admin.js';
import { createRuntimeApp } from './runtime.js';

async function main() {
  let config;
  try {
    config = loadConfig();
  } catch (err) {
    // Lists invalid keys only, never their values.
    console.error(err instanceof ConfigError ? err.message : 'Failed to load configuration');
    process.exit(1);
  }

  const logger = createLogger(config);
  const app = await createRuntimeApp(config, logger);
  logger.info({ credential: credentialSource(config).kind }, 'firebase admin credential source');

  const shutdown = async (signal: string) => {
    logger.info({ signal }, 'shutting down');
    try {
      await app.close();
      process.exit(0);
    } catch (err) {
      logger.error({ err }, 'error during shutdown');
      process.exit(1);
    }
  };
  process.once('SIGTERM', () => void shutdown('SIGTERM'));
  process.once('SIGINT', () => void shutdown('SIGINT'));

  await app.listen({ port: config.port, host: config.host });
  if (config.firebaseAuthEmulatorHost) {
    logger.warn('Firebase Auth emulator tokens are accepted (development only)');
  }
  if (config.firestoreEmulatorHost) {
    logger.warn('Using the Firestore emulator (development only)');
  }
  if (!config.firebaseProjectId.startsWith('demo-') && config.appEnv === 'development') {
    logger.warn({ project: config.firebaseProjectId }, 'Development server on the shared Firebase project: use test accounts only');
  }
  logger.info({ appCheckMode: config.appCheckMode, requireEmailVerification: config.requireEmailVerification }, 'security settings');
}

main().catch((err) => {
  console.error('Fatal startup error', err instanceof Error ? err.message : err);
  process.exit(1);
});
