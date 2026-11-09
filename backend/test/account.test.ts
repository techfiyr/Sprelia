import { describe, expect, it } from 'vitest';
import type { IdentityAdmin } from '../src/modules/account/identity-admin.js';
import type { AppCheckVerifier } from '../src/modules/app-check/app-check.js';
import type { AuthenticatedUser, TokenVerifier } from '../src/modules/auth/token-verifier.js';
import { InMemoryUserRepository } from '../src/modules/users/memory-user.repository.js';
import { FakeVerifier, LogCapture, makeApp, OTHER_TOKEN, OTHER_USER, testConfig, TEST_USER, VALID_TOKEN } from './helpers.js';

const NOW = new Date('2026-11-09T12:00:00Z');
const nowSeconds = NOW.getTime() / 1000;
const auth = (token = VALID_TOKEN) => ({ authorization: `Bearer ${token}` });

/** Verifier whose users signed in at a chosen time and with chosen verification state. */
class ConfigurableVerifier implements TokenVerifier {
  constructor(private readonly users: Record<string, AuthenticatedUser>) {}
  async verify(token: string) {
    const u = this.users[token];
    if (!u) return new FakeVerifier().verify(token);
    return u;
  }
}

class FakeIdentity implements IdentityAdmin {
  deleted: string[] = [];
  failNext = false;
  async deleteUser(uid: string) {
    if (this.failNext) {
      this.failNext = false;
      throw new Error('auth outage');
    }
    this.deleted.push(uid);
  }
}

async function seededRepo() {
  const users = new InMemoryUserRepository();
  for (const u of [TEST_USER, OTHER_USER]) {
    await users.createProfileIfAbsent({ uid: u.uid, email: u.email ?? null, displayName: null, timezone: 'UTC' });
    await users.saveOnboarding(u.uid, { level: 'B1' }, false);
    users.usage.set(`${u.uid}/2026-11-09`, 120);
    users.activity.set(`${u.uid}/2026-11-09`, { date: '2026-11-09', speakingSeconds: 120, sessionsCompleted: 1 });
  }
  return users;
}

describe('email verification gate (password accounts)', () => {
  const unverified: AuthenticatedUser = { ...TEST_USER, emailVerified: false };
  const google: AuthenticatedUser = { ...TEST_USER, emailVerified: false, signInProvider: 'google.com' };

  it.each([
    ['GET', '/api/v1/me/profile'],
    ['POST', '/api/v1/me/profile'],
    ['PUT', '/api/v1/me/onboarding'],
    ['GET', '/api/v1/me/dashboard'],
  ] as const)('%s %s rejects unverified email/password accounts', async (method, url) => {
    const app = await makeApp({ verifier: new ConfigurableVerifier({ [VALID_TOKEN]: unverified }) });
    const res = await app.inject({ method, url, headers: auth(), payload: method === 'GET' ? undefined : {} });
    expect(res.statusCode).toBe(403);
    expect(res.json().error.code).toBe('EMAIL_NOT_VERIFIED');
  });

  it('GET /me (identity) still works so the app can show the verification screen', async () => {
    const app = await makeApp({ verifier: new ConfigurableVerifier({ [VALID_TOKEN]: unverified }) });
    const res = await app.inject({ method: 'GET', url: '/api/v1/me', headers: auth() });
    expect(res.statusCode).toBe(200);
    expect(res.json().emailVerified).toBe(false);
  });

  it('federated (Google) accounts are not gated', async () => {
    const app = await makeApp({ verifier: new ConfigurableVerifier({ [VALID_TOKEN]: google }) });
    const res = await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { timezone: 'UTC' } });
    expect(res.statusCode).toBe(201);
  });

  it('can be disabled only outside staging/production', async () => {
    const app = await makeApp({
      config: testConfig({ REQUIRE_EMAIL_VERIFICATION: 'false' }),
      verifier: new ConfigurableVerifier({ [VALID_TOKEN]: unverified }),
    });
    const res = await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { timezone: 'UTC' } });
    expect(res.statusCode).toBe(201);
  });
});

describe('DELETE /me (account deletion)', () => {
  const recent: AuthenticatedUser = { ...TEST_USER, authTime: nowSeconds - 60 };
  const stale: AuthenticatedUser = { ...TEST_USER, authTime: nowSeconds - 3600 };
  const unverifiedRecent: AuthenticatedUser = { ...recent, emailVerified: false };

  async function setup(user: AuthenticatedUser) {
    const users = await seededRepo();
    const identity = new FakeIdentity();
    const logs = new LogCapture();
    const app = await makeApp({
      users,
      identity,
      logs,
      now: () => NOW,
      verifier: new ConfigurableVerifier({ [VALID_TOKEN]: user, [OTHER_TOKEN]: OTHER_USER }),
    });
    return { app, users, identity, logs };
  }

  it('requires authentication', async () => {
    const { app } = await setup(recent);
    expect((await app.inject({ method: 'DELETE', url: '/api/v1/me' })).statusCode).toBe(401);
  });

  it('requires a recent sign-in (403 REAUTH_REQUIRED) and deletes nothing otherwise', async () => {
    const { app, users, identity } = await setup(stale);
    const res = await app.inject({ method: 'DELETE', url: '/api/v1/me', headers: auth() });
    expect(res.statusCode).toBe(403);
    expect(res.json().error.code).toBe('REAUTH_REQUIRED');
    expect(await users.getProfile(TEST_USER.uid)).not.toBeNull();
    expect(identity.deleted).toEqual([]);
  });

  it('deletes all of the caller’s data, then the Auth user, and nobody else’s', async () => {
    const { app, users, identity, logs } = await setup(recent);
    const res = await app.inject({ method: 'DELETE', url: '/api/v1/me', headers: auth() });
    expect(res.statusCode).toBe(204);
    expect(await users.getProfile(TEST_USER.uid)).toBeNull();
    expect(await users.getPreferences(TEST_USER.uid)).toBeNull();
    expect(await users.getUsageSeconds(TEST_USER.uid, '2026-11-09')).toBe(0);
    expect(await users.getDailyActivity(TEST_USER.uid, ['2026-11-09'])).toEqual([]);
    expect(identity.deleted).toEqual([TEST_USER.uid]);

    expect(await users.getProfile(OTHER_USER.uid)).not.toBeNull();
    expect(await users.getUsageSeconds(OTHER_USER.uid, '2026-11-09')).toBe(120);
    expect(logs.text).not.toContain(TEST_USER.email!);
  });

  it('never takes a uid from the request', async () => {
    const { app, users, identity } = await setup(recent);
    const res = await app.inject({
      method: 'DELETE',
      url: `/api/v1/me?uid=${OTHER_USER.uid}`,
      headers: { ...auth(), 'content-type': 'application/json' },
      payload: { uid: OTHER_USER.uid },
    });
    expect(res.statusCode).toBe(204);
    expect(identity.deleted).toEqual([TEST_USER.uid]);
    expect(await users.getProfile(OTHER_USER.uid)).not.toBeNull();
  });

  it('is idempotent: a retry after a partial failure completes the deletion', async () => {
    const { app, users, identity } = await setup(recent);
    identity.failNext = true;
    const first = await app.inject({ method: 'DELETE', url: '/api/v1/me', headers: auth() });
    expect(first.statusCode).toBe(500);
    expect(await users.getProfile(TEST_USER.uid)).toBeNull();
    const retry = await app.inject({ method: 'DELETE', url: '/api/v1/me', headers: auth() });
    expect(retry.statusCode).toBe(204);
    expect(identity.deleted).toEqual([TEST_USER.uid]);
  });

  it('does not require email verification (anyone may delete their own account)', async () => {
    const { app } = await setup(unverifiedRecent);
    expect((await app.inject({ method: 'DELETE', url: '/api/v1/me', headers: auth() })).statusCode).toBe(204);
  });

  it('is not registered without an identity admin', async () => {
    const app = await makeApp();
    expect((await app.inject({ method: 'DELETE', url: '/api/v1/me', headers: auth() })).statusCode).toBe(404);
  });
});

describe('App Check guard', () => {
  const GOOD = 'aaa.bbb.ccc';
  class FakeAppCheck implements AppCheckVerifier {
    calls = 0;
    async verify(token: string) {
      this.calls++;
      if (token !== GOOD) throw new Error('invalid app check token');
      return { appId: '1:1:android:1' };
    }
  }
  const make = (mode: string, appCheck = new FakeAppCheck(), logs?: LogCapture) =>
    makeApp({ config: testConfig({ APP_CHECK_MODE: mode }), appCheck, logs });
  const get = (app: Awaited<ReturnType<typeof makeApp>>, url: string, appCheck?: string) =>
    app.inject({ method: 'GET', url, headers: { ...auth(), ...(appCheck ? { 'x-firebase-appcheck': appCheck } : {}) } });

  it('off: tokens are not checked', async () => {
    const verifier = new FakeAppCheck();
    const app = await make('off', verifier);
    expect((await get(app, '/api/v1/me')).statusCode).toBe(200);
    expect(verifier.calls).toBe(0);
  });

  it('monitor: missing or invalid tokens are logged and allowed; tokens are never logged', async () => {
    const logs = new LogCapture();
    const app = await make('monitor', new FakeAppCheck(), logs);
    expect((await get(app, '/api/v1/me')).statusCode).toBe(200);
    expect((await get(app, '/api/v1/me', 'xxx.yyy.zzz')).statusCode).toBe(200);
    expect(logs.text).toContain('app check failed');
    expect(logs.text).not.toContain('xxx.yyy.zzz');
  });

  it('enforce: missing, malformed or invalid tokens are rejected; valid ones pass', async () => {
    const app = await make('enforce');
    for (const token of [undefined, 'not-a-jwt', 'xxx.yyy.zzz']) {
      const res = await get(app, '/api/v1/me', token);
      expect(res.statusCode).toBe(403);
      expect(res.json().error.code).toBe('APP_CHECK_FAILED');
    }
    expect((await get(app, '/api/v1/me', GOOD)).statusCode).toBe(200);
    expect((await get(app, '/api/v1/practice/categories', GOOD)).statusCode).toBe(200);
  });

  it('enforce never blocks the health check', async () => {
    const app = await make('enforce');
    expect((await app.inject({ method: 'GET', url: '/api/v1/health' })).statusCode).toBe(200);
  });

  it('startup fails closed when a mode needs a verifier that is missing', async () => {
    await expect(makeApp({ config: testConfig({ APP_CHECK_MODE: 'enforce' }) })).rejects.toThrow(/requires an App Check verifier/);
  });
});
