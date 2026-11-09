import { randomUUID } from 'node:crypto';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyBaseLogger, type FastifyInstance } from 'fastify';
import { registerErrorHandling } from './common/error-handler.js';
import type { AppConfig } from './config/env.js';
import { accountRoutes } from './modules/account/account.routes.js';
import type { IdentityAdmin } from './modules/account/identity-admin.js';
import { appCheckGuard, type AppCheckVerifier } from './modules/app-check/app-check.js';
import type { TokenVerifier } from './modules/auth/token-verifier.js';
import { catalogRoutes } from './modules/catalog/catalog.routes.js';
import { CatalogService } from './modules/catalog/catalog.service.js';
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
  /** Published practice catalogue; defaults to the built-in catalogue for this config. */
  catalog?: CatalogService;
  /** Injectable clock for deterministic tests. */
  now?: () => Date;
  /** Firebase Auth admin operations; enables DELETE /me (account deletion). */
  identity?: IdentityAdmin;
  /** Required unless `config.appCheckMode` is `off` (startup fails closed otherwise). */
  appCheck?: AppCheckVerifier;
}

/**
 * Builds the HTTP application without listening, so tests can use `app.inject()`.
 * External services are injected (`verifier`) to keep modules testable.
 */
export async function buildApp({
  config,
  logger,
  verifier,
  users,
  catalog = new CatalogService({ includeDrafts: config.catalogIncludeDrafts }),
  now = () => new Date(),
  identity,
  appCheck,
}: AppDependencies): Promise<FastifyInstance> {
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
      // Everything except health is protected: App Check (per APP_CHECK_MODE) runs before
      // the per-route Firebase ID token verification.
      const checkApp = appCheckGuard(config.appCheckMode, appCheck);
      await api.register(async (secured) => {
        secured.addHook('preHandler', checkApp);
        await secured.register(meRoutes, { verifier });
        await secured.register(profileRoutes, {
          verifier,
          users,
          freeDailySeconds: config.freeDailySeconds,
          now,
          catalog,
          requireEmailVerification: config.requireEmailVerification,
        });
        await secured.register(catalogRoutes, { verifier, catalog });
        if (identity) {
          await secured.register(accountRoutes, {
            verifier,
            users,
            identity,
            recentAuthMaxAgeSeconds: config.recentAuthMaxAgeSeconds,
            now,
          });
        }
      });
    },
    { prefix: API_PREFIX },
  );

  return app;
}
