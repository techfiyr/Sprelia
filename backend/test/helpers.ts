import { Writable } from 'node:stream';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { createLogger } from '../src/common/logger.js';
import { invalidToken, authUnavailable } from '../src/common/errors.js';
import { loadConfig, type AppConfig } from '../src/config/env.js';
import type { IdentityAdmin } from '../src/modules/account/identity-admin.js';
import type { AppCheckVerifier } from '../src/modules/app-check/app-check.js';
import type { AIProvider } from '../src/modules/conversations/ai-provider.js';
import type { ConversationRepository } from '../src/modules/conversations/conversation.repository.js';
import type { ConversationAnalyzer } from '../src/modules/feedback/analysis.js';
import type { FeedbackRepository } from '../src/modules/feedback/feedback.repository.js';
import type { AuthenticatedUser, TokenVerifier } from '../src/modules/auth/token-verifier.js';
import { InMemoryUserRepository } from '../src/modules/users/memory-user.repository.js';
import type { UserRepository } from '../src/modules/users/user.repository.js';

export const VALID_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.c2lnbmF0dXJl';
export const REVOKED_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJyZXZva2VkIjp0cnVlfQ.c2lnbmF0dXJl';
export const OUTAGE_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJvdXRhZ2UiOnRydWV9.c2lnbmF0dXJl';
export const OTHER_TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyLTQ1NiJ9.c2lnbmF0dXJl';

export const OTHER_USER: AuthenticatedUser = {
  uid: 'user-456',
  email: 'other@example.com',
  emailVerified: true,
  signInProvider: 'password',
  authTime: 1_700_000_000,
};

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
    if (token === OTHER_TOKEN) return OTHER_USER;
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
  opts: {
    config?: AppConfig;
    verifier?: TokenVerifier;
    users?: UserRepository;
    now?: () => Date;
    logs?: LogCapture;
    register?: (app: FastifyInstance) => void;
    identity?: IdentityAdmin;
    appCheck?: AppCheckVerifier;
    conversations?: ConversationRepository;
    ai?: AIProvider;
    isPremium?: (uid: string) => Promise<boolean>;
    feedback?: FeedbackRepository;
    analyzer?: ConversationAnalyzer;
  } = {},
) {
  const config = opts.config ?? testConfig();
  const logger = createLogger(opts.logs ? { ...config, logLevel: 'info' } : config, opts.logs);
  const verifier = opts.verifier ?? new FakeVerifier();
  const users = opts.users ?? new InMemoryUserRepository();
  const app = await buildApp({
    config,
    logger,
    verifier,
    users,
    now: opts.now,
    identity: opts.identity,
    appCheck: opts.appCheck,
    conversations: opts.conversations,
    ai: opts.ai,
    isPremium: opts.isPremium,
    feedback: opts.feedback,
    analyzer: opts.analyzer,
  });
  opts.register?.(app);
  await app.ready();
  return app;
}
