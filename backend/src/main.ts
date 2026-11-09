import { buildApp } from './app.js';
import { createLogger } from './common/logger.js';
import { ConfigError, loadConfig } from './config/env.js';
import { firebaseAppCheck, firebaseAuth, firestore, initFirebaseAdmin } from './firebase/admin.js';
import { FirebaseIdentityAdmin } from './modules/account/identity-admin.js';
import { FirebaseAppCheckVerifier } from './modules/app-check/app-check.js';
import { FirebaseTokenVerifier } from './modules/auth/firebase-token-verifier.js';
import { FirestoreUserRepository } from './modules/users/firestore-user.repository.js';

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

  const users = new FirestoreUserRepository(firestore(firebase));

  const identity = new FirebaseIdentityAdmin(firebaseAuth(firebase));
  const appCheck = config.appCheckMode === 'off' ? undefined : new FirebaseAppCheckVerifier(firebaseAppCheck(firebase));

  const app = await buildApp({ config, logger, verifier, users, identity, appCheck });

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
