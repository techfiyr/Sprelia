import { describe, expect, it } from 'vitest';
import { createLogger } from '../src/common/logger.js';
import { loadConfig, parseServiceAccountJson } from '../src/config/env.js';
import { credentialSource } from '../src/firebase/admin.js';
import { LogCapture } from './helpers.js';

// Fake, non-functional key material (assembled so secret scanners don't mistake it for a key).
const FAKE_KEY = ['-----BEGIN', ' PRIVATE KEY-----\nTUlJRmFrZUtleUZvclRlc3RzT25seQ==\n-----END', ' PRIVATE KEY-----\n'].join('');
const MARKER = 'TUlJRmFrZUtleUZvclRlc3RzT25seQ';

const account = (overrides: Record<string, unknown> = {}) =>
  JSON.stringify({
    type: 'service_account',
    project_id: 'sprelia',
    private_key_id: 'fake-key-id-0000',
    private_key: FAKE_KEY,
    client_email: 'firebase-adminsdk-test@sprelia.iam.gserviceaccount.com',
    ...overrides,
  });

const real = { APP_ENV: 'development', FIREBASE_PROJECT_ID: 'sprelia' };

describe('FIREBASE_SERVICE_ACCOUNT_JSON', () => {
  it('accepts a valid key for the configured project; the private key is not enumerable', () => {
    const c = loadConfig({ ...real, FIREBASE_SERVICE_ACCOUNT_JSON: account() });
    expect(c.firebaseServiceAccount).toMatchObject({ projectId: 'sprelia', clientEmail: 'firebase-adminsdk-test@sprelia.iam.gserviceaccount.com' });
    expect(c.firebaseServiceAccount!.privateKey).toBe(FAKE_KEY);
    expect(Object.keys(c.firebaseServiceAccount!)).not.toContain('privateKey');
    expect(JSON.stringify(c)).not.toContain(MARKER);
    expect(credentialSource(c).kind).toBe('serviceAccount');
  });

  it.each([
    ['invalid JSON', `{"private_key": "${MARKER}"`, /valid JSON/],
    ['an array', '[]', /JSON object/],
    ['another key type', account({ type: 'authorized_user' }), /service_account/],
    ['another project', account({ project_id: 'someone-else' }), /different project/],
    ['an email from another project', account({ client_email: 'x-admin@someone-else.iam.gserviceaccount.com' }), /different project/],
    ['a malformed email', account({ client_email: 'not-an-email' }), /client_email/],
    ['a missing private key', account({ private_key: undefined }), /private_key/],
    ['a malformed private key', account({ private_key: MARKER }), /private_key/],
  ])('rejects %s without echoing any content', (_name, raw, reason) => {
    try {
      loadConfig({ ...real, FIREBASE_SERVICE_ACCOUNT_JSON: raw });
      expect.unreachable();
    } catch (e) {
      const message = (e as Error).message;
      expect(message).toMatch(reason);
      expect(message).toContain('FIREBASE_SERVICE_ACCOUNT_JSON');
      expect(message).not.toContain(MARKER);
      expect(message).not.toContain('firebase-adminsdk-test');
    }
  });

  it('is refused with the emulators, demo projects and in automated tests', () => {
    expect(() =>
      loadConfig({ FIREBASE_PROJECT_ID: 'demo-sprelia', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099', FIREBASE_SERVICE_ACCOUNT_JSON: account({ project_id: 'demo-sprelia' }) }),
    ).toThrowError(/must not be set with the emulators/);
    expect(() => loadConfig({ APP_ENV: 'test', FIREBASE_PROJECT_ID: 'demo-sprelia', FIREBASE_SERVICE_ACCOUNT_JSON: account() })).toThrowError(
      /FIREBASE_SERVICE_ACCOUNT_JSON/,
    );
  });

  it('rejects oversized values', () => {
    expect(parseServiceAccountJson('x'.repeat(17 * 1024), 'sprelia')).toEqual({ ok: false, reason: 'is too large to be a service account key' });
  });

  it('credential source: emulator, then secret, then Application Default Credentials', () => {
    expect(credentialSource({ firebaseAuthEmulatorHost: '127.0.0.1:9099' }).kind).toBe('emulator');
    expect(credentialSource({}).kind).toBe('applicationDefault');
  });

  it('is never written to logs, even if a config or env object is logged by mistake', () => {
    const logs = new LogCapture();
    const c = loadConfig({ ...real, FIREBASE_SERVICE_ACCOUNT_JSON: account() });
    const logger = createLogger({ logLevel: 'info', appEnv: 'development' }, logs);
    logger.info({ config: c, env: { FIREBASE_SERVICE_ACCOUNT_JSON: account() }, private_key: FAKE_KEY }, 'oops');
    expect(logs.text).toContain('oops');
    expect(logs.text).not.toContain(MARKER);
  });
});
