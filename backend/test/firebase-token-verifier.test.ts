import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AppError } from '../src/common/errors.js';
import { FirebaseTokenVerifier } from '../src/modules/auth/firebase-token-verifier.js';

const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');

async function expectAppError(p: Promise<unknown>, statusCode: number, code: string) {
  const err = await p.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err).toBeInstanceOf(AppError);
  expect((err as AppError).statusCode).toBe(statusCode);
  expect((err as AppError).code).toBe(code);
}

describe('FirebaseTokenVerifier with the real Admin SDK (offline cases)', () => {
  let app: App;
  let verifier: FirebaseTokenVerifier;

  beforeAll(() => {
    // Make sure no emulator setting leaks in: emulator mode accepts unsigned tokens.
    delete process.env.FIREBASE_AUTH_EMULATOR_HOST;
    app = initializeApp({ projectId: 'demo-sprelia' }, 'verifier-test');
    verifier = new FirebaseTokenVerifier(getAuth(app), { checkRevoked: false });
  });
  afterAll(() => deleteApp(app));

  it('rejects a malformed token as INVALID_TOKEN', async () => {
    await expectAppError(verifier.verify('not.a.jwt'), 401, 'INVALID_TOKEN');
  });

  it('rejects an unsigned (alg=none) token as INVALID_TOKEN', async () => {
    const now = Math.floor(Date.now() / 1000);
    const forged = `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
      aud: 'demo-sprelia',
      iss: 'https://securetoken.google.com/demo-sprelia',
      sub: 'attacker',
      iat: now,
      exp: now + 3600,
      auth_time: now,
    })}.`;
    await expectAppError(verifier.verify(forged), 401, 'INVALID_TOKEN');
  });

  it('rejects a token issued for another project as INVALID_TOKEN', async () => {
    const now = Math.floor(Date.now() / 1000);
    const otherProject = `${b64({ alg: 'RS256', kid: 'x', typ: 'JWT' })}.${b64({
      aud: 'some-other-project',
      iss: 'https://securetoken.google.com/some-other-project',
      sub: 'attacker',
      iat: now,
      exp: now + 3600,
      auth_time: now,
    })}.c2ln`;
    await expectAppError(verifier.verify(otherProject), 401, 'INVALID_TOKEN');
  });
});

describe('FirebaseTokenVerifier error mapping', () => {
  const failingAuth = (err: unknown) =>
    ({ verifyIdToken: async () => Promise.reject(err) }) as unknown as Auth;

  it.each(['auth/id-token-expired', 'auth/id-token-revoked', 'auth/user-disabled', 'auth/invalid-id-token'])(
    'maps %s to 401 INVALID_TOKEN',
    async (code) => {
      const v = new FirebaseTokenVerifier(failingAuth({ code }), { checkRevoked: true });
      await expectAppError(v.verify('a.b.c'), 401, 'INVALID_TOKEN');
    },
  );

  it('maps unexpected failures to 503 SERVICE_UNAVAILABLE', async () => {
    const v = new FirebaseTokenVerifier(failingAuth(new Error('socket hang up')), { checkRevoked: true });
    await expectAppError(v.verify('a.b.c'), 503, 'SERVICE_UNAVAILABLE');
  });

  it('passes checkRevoked through and maps the decoded token', async () => {
    let seenCheckRevoked: boolean | undefined;
    const auth = {
      verifyIdToken: async (_t: string, checkRevoked?: boolean) => {
        seenCheckRevoked = checkRevoked;
        return {
          uid: 'u1',
          email: 'a@example.com',
          email_verified: false,
          auth_time: 1,
          firebase: { sign_in_provider: 'google.com' },
        };
      },
    } as unknown as Auth;
    const user = await new FirebaseTokenVerifier(auth, { checkRevoked: true }).verify('a.b.c');
    expect(seenCheckRevoked).toBe(true);
    expect(user).toEqual({ uid: 'u1', email: 'a@example.com', emailVerified: false, signInProvider: 'google.com', authTime: 1 });
  });
});
