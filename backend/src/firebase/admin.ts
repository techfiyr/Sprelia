import { applicationDefault, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAppCheck, type AppCheck } from 'firebase-admin/app-check';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import type { AppConfig } from '../config/env.js';

/**
 * Initializes the Firebase Admin SDK once per process.
 *
 * Credentials come from Application Default Credentials:
 * - Cloud Run: the service's attached service account (no key files).
 * - Local: `gcloud auth application-default login`, or the Auth emulator via
 *   FIREBASE_AUTH_EMULATOR_HOST (which needs no credentials).
 * Service-account JSON key files must never be committed or baked into images.
 *
 * NOTE: the Admin SDK bypasses Firestore Security Rules. Every Admin write must be
 * authorized and validated in backend code.
 */
export function initFirebaseAdmin(config: AppConfig): App {
  const existing = getApps()[0];
  if (existing) return existing;
  // firebase-admin reads emulator hosts from process env; config validation has
  // already guaranteed we are not in staging/production.
  if (config.firestoreEmulatorHost) process.env.FIRESTORE_EMULATOR_HOST = config.firestoreEmulatorHost;
  if (config.firebaseAuthEmulatorHost) {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = config.firebaseAuthEmulatorHost;
    return initializeApp({ projectId: config.firebaseProjectId });
  }
  return initializeApp({ credential: applicationDefault(), projectId: config.firebaseProjectId });
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
