import { describe, expect, it } from 'vitest';
import { ConfigError, loadConfig } from '../src/config/env.js';

const base = { FIREBASE_PROJECT_ID: 'demo-sprelia', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' };

describe('loadConfig', () => {
  it('applies safe defaults', () => {
    const c = loadConfig(base);
    expect(c).toMatchObject({ appEnv: 'development', port: 8080, authCheckRevoked: true, trustProxyHops: 0 });
  });

  it('requires a Firebase project id', () => {
    expect(() => loadConfig({})).toThrowError(ConfigError);
  });

  it.each(['staging', 'production'])('forbids the Auth emulator in %s', (env) => {
    expect(() =>
      loadConfig({ ...base, APP_ENV: env, FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' }),
    ).toThrowError(/FIREBASE_AUTH_EMULATOR_HOST/);
  });

  it.each(['staging', 'production'])('forbids disabling revocation checks in %s', (env) => {
    expect(() => loadConfig({ ...base, APP_ENV: env, AUTH_CHECK_REVOKED: 'false' })).toThrowError(
      /AUTH_CHECK_REVOKED/,
    );
  });

  it('allows the Auth emulator in development', () => {
    const c = loadConfig({ ...base, FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' });
    expect(c.firebaseAuthEmulatorHost).toBe('127.0.0.1:9099');
  });

  it('never includes values in error messages', () => {
    try {
      loadConfig({ FIREBASE_PROJECT_ID: 'Sup3r$ecret-Value!', PORT: 'not-a-port' });
      expect.unreachable();
    } catch (e) {
      expect((e as Error).message).not.toContain('Sup3r$ecret-Value!');
      expect((e as Error).message).toContain('FIREBASE_PROJECT_ID');
      expect((e as Error).message).toContain('PORT');
    }
  });
});

describe('FIREBASE_PROJECT_ID', () => {
  it('rejects a project number', () => {
    expect(() => loadConfig({ FIREBASE_PROJECT_ID: '756773147926' })).toThrowError(/project number/);
  });
  it('accepts the approved project and demo emulator projects only', () => {
    expect(loadConfig({ FIREBASE_PROJECT_ID: 'sprelia' }).firebaseProjectId).toBe('sprelia');
    expect(loadConfig(base).firebaseProjectId).toBe('demo-sprelia');
    expect(() => loadConfig({ FIREBASE_PROJECT_ID: 'sprelia-dev' })).toThrowError(/approved project/);
    expect(() => loadConfig({ FIREBASE_PROJECT_ID: 'someone-else' })).toThrowError(/approved project/);
  });
  it('demo projects need the emulators', () => {
    expect(() => loadConfig({ FIREBASE_PROJECT_ID: 'demo-sprelia' })).toThrowError(/emulators/);
  });
});

describe('single Firebase project guard (owner decision 2026-11-09)', () => {
  const prod = { APP_ENV: 'production', TRUST_PROXY_HOPS: '1' };
  it.each(['staging', 'production'])('%s must use sprelia', (env) => {
    expect(loadConfig({ ...prod, APP_ENV: env, FIREBASE_PROJECT_ID: 'sprelia' }).firebaseProjectId).toBe('sprelia');
    expect(() => loadConfig({ ...prod, APP_ENV: env, FIREBASE_PROJECT_ID: 'demo-sprelia' })).toThrowError(/approved project/);
  });
  it('development may use sprelia (pre-launch, test accounts only)', () => {
    expect(loadConfig({ APP_ENV: 'development', FIREBASE_PROJECT_ID: 'sprelia' }).firebaseProjectId).toBe('sprelia');
  });
  it('automated tests fail closed on any real project', () => {
    expect(() => loadConfig({ APP_ENV: 'test', FIREBASE_PROJECT_ID: 'sprelia' })).toThrowError(/demo-\* emulator project/);
    expect(loadConfig({ APP_ENV: 'test', FIREBASE_PROJECT_ID: 'demo-sprelia' }).appEnv).toBe('test');
  });
  it('drafts are never published in production', () => {
    expect(loadConfig({ ...prod, FIREBASE_PROJECT_ID: 'sprelia' }).catalogIncludeDrafts).toBe(false);
    expect(() => loadConfig({ ...prod, FIREBASE_PROJECT_ID: 'sprelia', CATALOG_INCLUDE_DRAFTS: 'true' })).toThrowError(/unreviewed/);
    expect(loadConfig(base).catalogIncludeDrafts).toBe(true);
  });
});

describe('App Check and account security settings', () => {
  const prod = { APP_ENV: 'production', TRUST_PROXY_HOPS: '1', FIREBASE_PROJECT_ID: 'sprelia' };
  it('defaults: production enforce, staging monitor, development off', () => {
    expect(loadConfig(prod).appCheckMode).toBe('enforce');
    expect(loadConfig({ ...prod, APP_ENV: 'staging' }).appCheckMode).toBe('monitor');
    expect(loadConfig(base).appCheckMode).toBe('off');
  });
  it('production cannot relax App Check', () => {
    expect(() => loadConfig({ ...prod, APP_CHECK_MODE: 'monitor' })).toThrowError(/APP_CHECK_MODE/);
    expect(() => loadConfig({ ...prod, APP_CHECK_MODE: 'off' })).toThrowError(/APP_CHECK_MODE/);
  });
  it('email verification and recent sign-in defaults', () => {
    expect(loadConfig(base)).toMatchObject({ requireEmailVerification: true, recentAuthMaxAgeSeconds: 300 });
    expect(() => loadConfig({ ...prod, REQUIRE_EMAIL_VERIFICATION: 'false' })).toThrowError(/REQUIRE_EMAIL_VERIFICATION/);
    expect(() => loadConfig({ ...base, RECENT_AUTH_MAX_AGE_SECONDS: '5' })).toThrowError(/RECENT_AUTH_MAX_AGE_SECONDS/);
  });
});
