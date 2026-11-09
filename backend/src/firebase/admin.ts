import { applicationDefault, cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAppCheck, type AppCheck } from 'firebase-admin/app-check';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import type { AppConfig, FirebaseServiceAccount } from '../config/env.js';

/**
 * Initializes the Firebase Admin SDK once per process.
 *
 * Credentials (see `credentialSource`):
 * - Emulators: none needed.
 * - FIREBASE_SERVICE_ACCOUNT_JSON secret (hosts without workload identity, e.g. Netlify):
 *   validated at config load, used via `cert()`, never logged.
 * - Otherwise Application Default Credentials: `gcloud auth application-default login`
 *   locally, or the attached service account on Google Cloud.
 * Service-account JSON key files must never be committed or baked into images.
 *
 * NOTE: the Admin SDK bypasses Firestore Security Rules. Every Admin write must be
 * authorized and validated in backend code.
 */
export type CredentialSource =
  | { kind: 'emulator' }
  | { kind: 'serviceAccount'; account: FirebaseServiceAccount }
  | { kind: 'applicationDefault' };

/** Pure decision (unit-tested): which credential the Admin SDK uses for this config. */
export function credentialSource(config: Pick<AppConfig, 'firebaseAuthEmulatorHost' | 'firebaseServiceAccount'>): CredentialSource {
  if (config.firebaseAuthEmulatorHost) return { kind: 'emulator' };
  if (config.firebaseServiceAccount) return { kind: 'serviceAccount', account: config.firebaseServiceAccount };
  return { kind: 'applicationDefault' };
}

export function initFirebaseAdmin(config: AppConfig): App {
  const existing = getApps()[0];
  if (existing) return existing;
  // firebase-admin reads emulator hosts from process env; config validation has
  // already guaranteed we are not in staging/production.
  if (config.firestoreEmulatorHost) process.env.FIRESTORE_EMULATOR_HOST = config.firestoreEmulatorHost;
  const source = credentialSource(config);
  switch (source.kind) {
    case 'emulator':
      process.env.FIREBASE_AUTH_EMULATOR_HOST = config.firebaseAuthEmulatorHost;
      return initializeApp({ projectId: config.firebaseProjectId });
    case 'serviceAccount': {
      const { projectId, clientEmail, privateKey } = source.account;
      return initializeApp({ credential: cert({ projectId, clientEmail, privateKey }), projectId: config.firebaseProjectId });
    }
    case 'applicationDefault':
      return initializeApp({ credential: applicationDefault(), projectId: config.firebaseProjectId });
  }
}

export function firebaseAuth(app: App): Auth {
  return getAuth(app);
}

export function firebaseAppCheck(app: App): AppCheck {
  return getAppCheck(app);
}

export function firestore(app: App): Firestore {
  return getFirestore(app);
}
