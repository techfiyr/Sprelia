import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../../src/app.js';
import { createLogger } from '../../src/common/logger.js';
import { loadConfig } from '../../src/config/env.js';
import { FirebaseTokenVerifier } from '../../src/modules/auth/firebase-token-verifier.js';
import { FirestoreUserRepository } from '../../src/modules/users/firestore-user.repository.js';

/**
 * End-to-end against the Firebase Emulator Suite: real Auth emulator ID tokens,
 * real Admin SDK verification (incl. revocation checks) and real Firestore writes.
 */
const PROJECT_ID = 'demo-sprelia';
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST;
if (!AUTH_HOST || !FIRESTORE_HOST) {
  throw new Error('Run with `npm run test:integration` (requires the Auth and Firestore emulators).');
}

async function emulatorSignUp(email: string): Promise<{ idToken: string; localId: string }> {
  // The Auth emulator accepts any API key; this is not a credential.
  const res = await fetch(`http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: 'emulator-password-1', returnSecureToken: true }),
  });
  if (!res.ok) throw new Error(`emulator sign-up failed: ${res.status}`);
  return (await res.json()) as { idToken: string; localId: string };
}

async function clearEmulators() {
  await fetch(`http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: 'DELETE' });
}

describe('API on the Firebase Emulator Suite', () => {
  let firebase: App;
  let db: Firestore;
  let app: FastifyInstance;
  let alice: { idToken: string; localId: string };
  let bob: { idToken: string; localId: string };

  beforeAll(async () => {
    await clearEmulators();
    firebase = initializeApp({ projectId: PROJECT_ID }, 'integration');
    db = getFirestore(firebase);
    const config = loadConfig({
      APP_ENV: 'test',
      FIREBASE_PROJECT_ID: PROJECT_ID,
      FIREBASE_AUTH_EMULATOR_HOST: AUTH_HOST,
      FIRESTORE_EMULATOR_HOST: FIRESTORE_HOST,
      LOG_LEVEL: 'silent',
    });
    app = await buildApp({
      config,
      logger: createLogger(config),
      verifier: new FirebaseTokenVerifier(getAuth(firebase), { checkRevoked: true }),
      users: new FirestoreUserRepository(db),
    });
    await app.ready();
    alice = await emulatorSignUp('alice@example.com');
    bob = await emulatorSignUp('bob@example.com');
  });

  afterAll(async () => {
    await app?.close();
    if (firebase) await deleteApp(firebase);
  });

  const call = (method: 'GET' | 'POST' | 'PUT', url: string, token?: string, payload?: object) =>
    app.inject({ method, url, payload, headers: token ? { authorization: `Bearer ${token}` } : {} });

  it('verifies real ID tokens and rejects missing or tampered ones', async () => {
    expect((await call('GET', '/api/v1/me')).statusCode).toBe(401);
    const me = await call('GET', '/api/v1/me', alice.idToken);
    expect(me.statusCode).toBe(200);
    expect(me.json()).toMatchObject({ uid: alice.localId, email: 'alice@example.com', signInProvider: 'password' });

    const [h, p] = alice.idToken.split('.');
    const claims = JSON.parse(Buffer.from(p!, 'base64url').toString());
    const forged = `${h}.${Buffer.from(JSON.stringify({ ...claims, aud: 'another-project' })).toString('base64url')}.`;
    expect((await call('GET', '/api/v1/me', forged)).json().error.code).toBe('INVALID_TOKEN');
  });

  it('creates the profile in Firestore with server-owned fields', async () => {
    const res = await call('POST', '/api/v1/me/profile', alice.idToken, { displayName: 'Alice', timezone: 'Europe/London' });
    expect(res.statusCode).toBe(201);
    const doc = await db.collection('users').doc(alice.localId).get();
    expect(doc.exists).toBe(true);
    expect(doc.data()).toMatchObject({
      uid: alice.localId,
      email: 'alice@example.com',
      displayName: 'Alice',
      timezone: 'Europe/London',
      onboardingStatus: 'not_started',
      schemaVersion: 1,
    });
    expect((await call('POST', '/api/v1/me/profile', alice.idToken, { timezone: 'UTC' })).statusCode).toBe(200);
  });

  it('saves onboarding transactionally and builds the dashboard', async () => {
    const partial = await call('PUT', '/api/v1/me/onboarding', alice.idToken, {
      preferences: { interfaceLanguage: 'en', nativeLanguage: 'es' },
    });
    expect(partial.json().profile.onboarding.status).toBe('in_progress');

    const done = await call('PUT', '/api/v1/me/onboarding', alice.idToken, {
      preferences: { goals: ['travel_social'], level: 'B2', dailyGoalMinutes: 15, accent: 'british' },
      complete: true,
    });
    expect(done.statusCode).toBe(200);
    expect(done.json().plan.tutorId).toBe('sofia');

    const prefs = await db.doc(`users/${alice.localId}/preferences/learning`).get();
    expect(prefs.data()).toMatchObject({ interfaceLanguage: 'en', nativeLanguage: 'es', level: 'B2', dailyGoalMinutes: 15 });

    const dash = await call('GET', '/api/v1/me/dashboard', alice.idToken);
    expect(dash.statusCode).toBe(200);
    expect(dash.json().dashboard).toMatchObject({ dailyGoalMinutes: 15, plan: 'free', progress: { streakDays: 0 } });
  });

  it('isolates users: Bob cannot see or modify Alice’s data', async () => {
    expect((await call('GET', '/api/v1/me/profile', bob.idToken)).statusCode).toBe(404);
    const write = await call('PUT', '/api/v1/me/onboarding', bob.idToken, { preferences: { level: 'A1' } });
    expect(write.statusCode).toBe(404);
    const alicePrefs = await db.doc(`users/${alice.localId}/preferences/learning`).get();
    expect(alicePrefs.get('level')).toBe('B2');
  });

  it('rejects tokens of a disabled user (revocation checks enabled)', async () => {
    await getAuth(firebase).updateUser(bob.localId, { disabled: true });
    const res = await call('GET', '/api/v1/me', bob.idToken);
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('INVALID_TOKEN');
  });
});
