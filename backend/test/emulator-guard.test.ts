import { describe, expect, it } from 'vitest';
import { assertEmulatorOnly } from './integration/emulator-guard.js';

const ok = {
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099',
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:8180',
  GCLOUD_PROJECT: 'demo-sprelia',
};

describe('integration emulator guard (fails closed)', () => {
  it('accepts the local emulators with a demo project', () => {
    expect(assertEmulatorOnly(ok)).toEqual({ authHost: '127.0.0.1:9099', firestoreHost: '127.0.0.1:8180' });
  });
  it.each([
    ['no emulators', {}],
    ['missing Firestore emulator', { ...ok, FIRESTORE_EMULATOR_HOST: undefined }],
    ['remote emulator host', { ...ok, FIREBASE_AUTH_EMULATOR_HOST: 'auth.example.com:9099' }],
    ['the real project', { ...ok, GCLOUD_PROJECT: 'sprelia' }],
    ['a real project id', { ...ok, FIREBASE_PROJECT_ID: 'sprelia' }],
    ['real credentials', { ...ok, GOOGLE_APPLICATION_CREDENTIALS: '/tmp/key.json' }],
  ])('refuses %s', (_name, env) => {
    expect(() => assertEmulatorOnly(env as NodeJS.ProcessEnv)).toThrowError(/Refusing to run integration tests/);
  });
});
