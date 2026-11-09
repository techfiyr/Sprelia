import { buildApp } from './app.js';
import { createLogger } from './common/logger.js';
import { ConfigError, loadConfig } from './config/env.js';
import { firebaseAuth, initFirebaseAdmin } from './firebase/admin.js';
import { FirebaseTokenVerifier } from './modules/auth/firebase-token-verifier.js';

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
  const firebase = initFirebaseAdmin(config);
  const verifier = new FirebaseTokenVerifier(firebaseAuth(firebase), {
    checkRevoked: config.authCheckRevoked,
  });

  const app = await buildApp({ config, logger, verifier });

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
}

main().catch((err) => {
  console.error('Fatal startup error', err instanceof Error ? err.message : err);
  process.exit(1);
});
