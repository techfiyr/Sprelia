import { randomUUID } from 'node:crypto';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyBaseLogger, type FastifyInstance } from 'fastify';
import { registerErrorHandling } from './common/error-handler.js';
import type { AppConfig } from './config/env.js';
import type { TokenVerifier } from './modules/auth/token-verifier.js';
import { catalogRoutes } from './modules/catalog/catalog.routes.js';
import { healthRoutes } from './modules/health/health.routes.js';
import { meRoutes } from './modules/users/me.routes.js';
import { profileRoutes } from './modules/users/profile.routes.js';
import type { UserRepository } from './modules/users/user.repository.js';

export const API_PREFIX = '/api/v1';
const BODY_LIMIT_BYTES = 64 * 1024;
const SAFE_REQUEST_ID = /^[A-Za-z0-9._-]{8,64}$/;

export interface AppDependencies {
  config: AppConfig;
  logger: FastifyBaseLogger;
  verifier: TokenVerifier;
  users: UserRepository;
  /** Injectable clock for deterministic tests. */
  now?: () => Date;
}

/**
 * Builds the HTTP application without listening, so tests can use `app.inject()`.
 * External services are injected (`verifier`) to keep modules testable.
 */
export async function buildApp({ config, logger, verifier, users, now = () => new Date() }: AppDependencies): Promise<FastifyInstance> {
  const app = Fastify({
    loggerInstance: logger,
    bodyLimit: BODY_LIMIT_BYTES,
    // Trust only the first N proxy hops (Cloud Run front end = 1) for client IPs.
    trustProxy: config.trustProxyHops > 0 ? (_address: string, hop: number) => hop < config.trustProxyHops : false,
    // Accept a caller-supplied request ID only if it is short and safe to log.
    requestIdHeader: false,
    genReqId: (req) => {
      const incoming = req.headers['x-request-id'];
      return typeof incoming === 'string' && SAFE_REQUEST_ID.test(incoming) ? incoming : randomUUID();
    },
    routerOptions: { ignoreTrailingSlash: true },
  });

  registerErrorHandling(app);

  app.addHook('onSend', async (request, reply) => {
    reply.header('x-request-id', request.id);
  });

  await app.register(helmet, { global: true });
  await app.register(rateLimit, {
    global: true,
    max: config.rateLimitPerMinute,
    timeWindow: '1 minute',
  });

  await app.register(
    async (api) => {
      await api.register(healthRoutes);
      await api.register(meRoutes, { verifier });
      await api.register(profileRoutes, { verifier, users, freeDailySeconds: config.freeDailySeconds, now });
      await api.register(catalogRoutes, { verifier });
    },
    { prefix: API_PREFIX },
  );

  return app;
}
