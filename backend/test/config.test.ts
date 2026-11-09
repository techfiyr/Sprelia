import { describe, expect, it } from 'vitest';
import { ConfigError, loadConfig } from '../src/config/env.js';

const base = { FIREBASE_PROJECT_ID: 'demo-sprelia' };

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
  it('accepts real and demo project IDs', () => {
    expect(loadConfig({ FIREBASE_PROJECT_ID: 'sprelia' }).firebaseProjectId).toBe('sprelia');
    expect(loadConfig({ FIREBASE_PROJECT_ID: 'demo-sprelia' }).firebaseProjectId).toBe('demo-sprelia');
  });
});
