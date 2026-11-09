import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../../src/app.js';
import { createLogger } from '../../src/common/logger.js';
import { loadConfig } from '../../src/config/env.js';
import { FirebaseIdentityAdmin } from '../../src/modules/account/identity-admin.js';
import { FirebaseTokenVerifier } from '../../src/modules/auth/firebase-token-verifier.js';
import { FirestoreUserRepository } from '../../src/modules/users/firestore-user.repository.js';
import { assertEmulatorOnly, EMULATOR_PROJECT_ID } from './emulator-guard.js';

/**
 * End-to-end against the Firebase Emulator Suite: real Auth emulator ID tokens,
 * real Admin SDK verification (incl. revocation checks) and real Firestore writes.
 */
const PROJECT_ID = EMULATOR_PROJECT_ID;
const { authHost: AUTH_HOST, firestoreHost: FIRESTORE_HOST } = assertEmulatorOnly();

type Session = { idToken: string; localId: string };
const PASSWORD = 'emulator-password-1';

/** Identity Toolkit REST on the Auth emulator. The emulator accepts any API key; not a credential. */
async function identity(method: string, body: object): Promise<Response> {
  return fetch(`http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:${method}?key=emulator-only`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

async function ok<T>(res: Response, what: string): Promise<T> {
  if (!res.ok) throw new Error(`${what} failed: ${res.status} ${await res.text()}`);
  return (await res.json()) as T;
}

/** Registration (unverified email/password account). */
async function emulatorSignUp(email: string): Promise<Session> {
  return ok(await identity('signUp', { email, password: PASSWORD, returnSecureToken: true }), 'sign-up');
}

async function emulatorSignIn(email: string, password = PASSWORD): Promise<Session> {
  return ok(await identity('signInWithPassword', { email, password, returnSecureToken: true }), 'sign-in');
}

/** The newest out-of-band code (verification / reset email) the emulator "sent" to [email]. */
async function latestOobCode(email: string, requestType: 'VERIFY_EMAIL' | 'PASSWORD_RESET'): Promise<string> {
  const res = await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT_ID}/oobCodes`);
  const { oobCodes } = await ok<{ oobCodes: { email: string; oobCode: string; requestType: string }[] }>(res, 'oob codes');
  const code = oobCodes.filter((c) => c.email === email && c.requestType === requestType).at(-1);
  if (!code) throw new Error(`no ${requestType} email for ${email}`);
  return code.oobCode;
}

/** Sends the verification email, follows its link, then signs in again (fresh token, email_verified=true). */
async function verifyEmail(email: string, session: Session): Promise<Session> {
  await ok(await identity('sendOobCode', { requestType: 'VERIFY_EMAIL', idToken: session.idToken }), 'send verification');
  await ok(await identity('update', { oobCode: await latestOobCode(email, 'VERIFY_EMAIL') }), 'apply verification');
  return emulatorSignIn(email);
}

async function verifiedSignUp(email: string): Promise<Session> {
  return verifyEmail(email, await emulatorSignUp(email));
}

/** Google sign-in on the emulator: it accepts an unsigned JSON id_token (emulator only). */
async function emulatorGoogleSignIn(email: string, sub: string): Promise<Session> {
  const idToken = JSON.stringify({ sub, email, email_verified: true });
  return ok(
    await identity('signInWithIdp', {
      postBody: `id_token=${encodeURIComponent(idToken)}&providerId=google.com`,
      requestUri: 'http://localhost',
      returnSecureToken: true,
    }),
    'google sign-in',
  );
}

async function clearEmulators() {
  assertEmulatorOnly(); // re-checked immediately before every wipe
  await fetch(`http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: 'DELETE' });
}

describe('API on the Firebase Emulator Suite', () => {
  let firebase: App;
  let db: Firestore;
  let app: FastifyInstance;
  let laterApp: FastifyInstance;
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
    const deps = {
      config,
      logger: createLogger(config),
      verifier: new FirebaseTokenVerifier(getAuth(firebase), { checkRevoked: true }),
      users: new FirestoreUserRepository(db),
      identity: new FirebaseIdentityAdmin(getAuth(firebase)),
    };
    app = await buildApp(deps);
    await app.ready();
    // Same app, but its clock is an hour ahead: every sign-in looks stale.
    laterApp = await buildApp({ ...deps, now: () => new Date(Date.now() + 3600_000) });
    await laterApp.ready();
    alice = await verifiedSignUp('alice@example.com');
    bob = await verifiedSignUp('bob@example.com');
  });

  afterAll(async () => {
    await app?.close();
    await laterApp?.close();
    if (firebase) await deleteApp(firebase);
  });

  const call = (method: 'GET' | 'POST' | 'PUT' | 'DELETE', url: string, token?: string, payload?: object, on = app) =>
    on.inject({ method, url, payload, headers: token ? { authorization: `Bearer ${token}` } : {} });

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

  describe('Phase 3 account flows', () => {
    it('registration and login; invalid credentials are rejected without revealing which part was wrong', async () => {
      const carol = await emulatorSignUp('carol@example.com');
      expect((await emulatorSignIn('carol@example.com')).localId).toBe(carol.localId);
      const wrong = await identity('signInWithPassword', { email: 'carol@example.com', password: 'wrong-pass-1', returnSecureToken: true });
      const unknown = await identity('signInWithPassword', { email: 'nobody@example.com', password: PASSWORD, returnSecureToken: true });
      expect(wrong.status).toBe(400);
      expect(unknown.status).toBe(400);
    });

    it('email verification: unverified accounts are refused until the link is followed', async () => {
      const dan = await emulatorSignUp('dan@example.com');
      const before = await call('POST', '/api/v1/me/profile', dan.idToken, { timezone: 'UTC' });
      expect(before.statusCode).toBe(403);
      expect(before.json().error.code).toBe('EMAIL_NOT_VERIFIED');
      expect((await db.collection('users').doc(dan.localId).get()).exists).toBe(false);

      const verified = await verifyEmail('dan@example.com', dan);
      expect((await call('GET', '/api/v1/me', verified.idToken)).json().emailVerified).toBe(true);
      expect((await call('POST', '/api/v1/me/profile', verified.idToken, { timezone: 'UTC' })).statusCode).toBe(201);
    });

    it('password reset: the emailed code sets a new password; the old one stops working', async () => {
      await verifiedSignUp('erin@example.com');
      await ok(await identity('sendOobCode', { requestType: 'PASSWORD_RESET', email: 'erin@example.com' }), 'send reset');
      const oobCode = await latestOobCode('erin@example.com', 'PASSWORD_RESET');
      await ok(await identity('resetPassword', { oobCode, newPassword: 'new-password-2' }), 'reset');
      expect((await identity('signInWithPassword', { email: 'erin@example.com', password: PASSWORD, returnSecureToken: true })).status).toBe(400);
      expect((await emulatorSignIn('erin@example.com', 'new-password-2')).idToken).toBeTruthy();
    });

    it('Google sign-in: verified federated identity, no email verification step', async () => {
      const gina = await emulatorGoogleSignIn('gina@example.com', 'google-sub-gina');
      const me = await call('GET', '/api/v1/me', gina.idToken);
      expect(me.json()).toMatchObject({ uid: gina.localId, signInProvider: 'google.com', emailVerified: true });
      expect((await call('POST', '/api/v1/me/profile', gina.idToken, { timezone: 'UTC' })).statusCode).toBe(201);
    });

    it('account deletion needs a recent sign-in', async () => {
      const hal = await verifiedSignUp('hal@example.com');
      const res = await call('DELETE', '/api/v1/me', hal.idToken, undefined, laterApp);
      expect(res.statusCode).toBe(403);
      expect(res.json().error.code).toBe('REAUTH_REQUIRED');
      expect((await getAuth(firebase).getUser(hal.localId)).uid).toBe(hal.localId);
    });

    it('account deletion removes all Firestore data and the Auth user; the old token stops working; others are untouched', async () => {
      const ivy = await verifiedSignUp('ivy@example.com');
      await call('POST', '/api/v1/me/profile', ivy.idToken, { timezone: 'UTC' });
      await call('PUT', '/api/v1/me/onboarding', ivy.idToken, { preferences: { level: 'A2' } });
      await db.doc(`users/${ivy.localId}/usage/2026-11-09`).set({ consumedSeconds: 60 });
      await db.doc(`users/${ivy.localId}/dailyProgress/2026-11-09`).set({ speakingSeconds: 60 });

      const res = await call('DELETE', '/api/v1/me', ivy.idToken);
      expect(res.statusCode).toBe(204);
      for (const path of [
        `users/${ivy.localId}`,
        `users/${ivy.localId}/preferences/learning`,
        `users/${ivy.localId}/usage/2026-11-09`,
        `users/${ivy.localId}/dailyProgress/2026-11-09`,
      ]) {
        expect((await db.doc(path).get()).exists, path).toBe(false);
      }
      await expect(getAuth(firebase).getUser(ivy.localId)).rejects.toMatchObject({ code: 'auth/user-not-found' });
      expect((await call('GET', '/api/v1/me', ivy.idToken)).statusCode).toBe(401);

      expect((await db.collection('users').doc(alice.localId).get()).exists).toBe(true);
      expect((await getAuth(firebase).getUser(alice.localId)).uid).toBe(alice.localId);
    });
  });
});
