import { Writable } from 'node:stream';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { createLogger } from '../src/common/logger.js';
import { invalidToken, authUnavailable } from '../src/common/errors.js';
import { loadConfig, type AppConfig } from '../src/config/env.js';
import type { AuthenticatedUser, TokenVerifier } from '../src/modules/auth/token-verifier.js';

export const VALID_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.c2lnbmF0dXJl';
export const REVOKED_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJyZXZva2VkIjp0cnVlfQ.c2lnbmF0dXJl';
export const OUTAGE_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJvdXRhZ2UiOnRydWV9.c2lnbmF0dXJl';

export const TEST_USER: AuthenticatedUser = {
  uid: 'user-123',
  email: 'learner@example.com',
  emailVerified: true,
  signInProvider: 'password',
  authTime: 1_700_000_000,
};

/** Deterministic verifier: no network, no Firebase. */
export class FakeVerifier implements TokenVerifier {
  calls: string[] = [];
  async verify(token: string): Promise<AuthenticatedUser> {
    this.calls.push(token);
    if (token === VALID_TOKEN) return TEST_USER;
    if (token === OUTAGE_TOKEN) throw authUnavailable(new Error('ECONNRESET fetching certs'));
    throw invalidToken(new Error('auth/id-token-revoked'));
  }
}

export function testConfig(overrides: NodeJS.ProcessEnv = {}): AppConfig {
  return loadConfig({ APP_ENV: 'test', FIREBASE_PROJECT_ID: 'demo-sprelia', LOG_LEVEL: 'silent', ...overrides });
}

/** Collects log lines so tests can assert nothing sensitive is written. */
export class LogCapture extends Writable {
  lines: string[] = [];
  override _write(chunk: Buffer, _enc: BufferEncoding, cb: () => void) {
    this.lines.push(chunk.toString());
    cb();
  }
  get text() {
    return this.lines.join('');
  }
}

export async function makeApp(
  opts: { config?: AppConfig; verifier?: TokenVerifier; logs?: LogCapture; register?: (app: FastifyInstance) => void } = {},
) {
  const config = opts.config ?? testConfig();
  const logger = createLogger(opts.logs ? { ...config, logLevel: 'info' } : config, opts.logs);
  const verifier = opts.verifier ?? new FakeVerifier();
  const app = await buildApp({ config, logger, verifier });
  opts.register?.(app);
  await app.ready();
  return app;
}
