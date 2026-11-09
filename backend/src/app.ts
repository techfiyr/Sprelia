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
import { UnavailableAIProvider, type AIProvider } from './modules/conversations/ai-provider.js';
import type { ConversationRepository } from './modules/conversations/conversation.repository.js';
import { conversationRoutes } from './modules/conversations/conversation.routes.js';
import { UnavailableAnalyzer, type ConversationAnalyzer } from './modules/feedback/analysis.js';
import type { FeedbackRepository } from './modules/feedback/feedback.repository.js';
import { feedbackRoutes } from './modules/feedback/feedback.routes.js';
import type { RevenueCatClient } from './modules/subscriptions/revenuecat.js';
import { isEntitled, type SubscriptionRepository } from './modules/subscriptions/subscription.repository.js';
import { revenueCatWebhookRoutes, subscriptionRoutes } from './modules/subscriptions/subscription.routes.js';
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
  /** Voice sessions and the usage ledger; enables /me/conversations. */
  conversations?: ConversationRepository;
  /** Realtime AI vendor; defaults to unavailable (503 VOICE_UNAVAILABLE). */
  ai?: AIProvider;
  /** Server-verified Premium entitlement (Phase 9); defaults to free for everyone. */
  isPremium?: (uid: string) => Promise<boolean>;
  /** Learning data (feedback, Mistake Vault, vocabulary); enables Phase 8 routes with `conversations`. */
  feedback?: FeedbackRepository;
  /** Post-session analysis; defaults to unavailable (feedback status `failed`). */
  analyzer?: ConversationAnalyzer;
  /** Server-side entitlement store (Phase 9). Enables /me/subscription and Premium checks. */
  subscriptions?: SubscriptionRepository;
  /** RevenueCat REST client; with REVENUECAT_WEBHOOK_AUTH enables the webhook. */
  revenueCat?: RevenueCatClient;
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
  conversations,
  ai = new UnavailableAIProvider(),
  isPremium: isPremiumOverride,
  feedback,
  analyzer = new UnavailableAnalyzer(),
  subscriptions,
  revenueCat,
}: AppDependencies): Promise<FastifyInstance> {
  const app = Fastify({
    loggerInstance: logger,
    bodyLimit: BODY_LIMIT_BYTES,
    // Trust only the first N proxy hops for client IPs (Netlify: 0; the adapter sets the client IP).
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

  const isPremium =
    isPremiumOverride ?? (subscriptions ? async (uid: string) => isEntitled(await subscriptions.get(uid), now()) : async () => false);

  await app.register(
    async (api) => {
      await api.register(healthRoutes);
      // Server-to-server: authenticated by the RevenueCat authorization value, outside the
      // Firebase-token and App Check scope. Registered only when fully configured.
      if (subscriptions && revenueCat && config.revenueCatWebhookAuth) {
        await api.register(revenueCatWebhookRoutes, {
          webhookAuth: config.revenueCatWebhookAuth,
          client: revenueCat,
          subscriptions,
          entitlementId: config.revenueCatEntitlementId,
          now,
        });
      }
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
          isPremium,
          premiumDailySeconds: config.premiumDailySeconds,
        });
        if (subscriptions) {
          await secured.register(subscriptionRoutes, {
            verifier,
            subscriptions,
            now,
            freeDailySeconds: config.freeDailySeconds,
            premiumDailySeconds: config.premiumDailySeconds,
          });
        }
        await secured.register(catalogRoutes, { verifier, catalog });
        if (conversations) {
          await secured.register(conversationRoutes, {
            verifier,
            users,
            conversations,
            catalog,
            ai,
            now,
            freeDailySeconds: config.freeDailySeconds,
            premiumDailySeconds: config.premiumDailySeconds,
            maxSessionSeconds: config.maxSessionSeconds,
            minSessionSeconds: config.minSessionSeconds,
            requireEmailVerification: config.requireEmailVerification,
            isPremium,
            feedback,
          });
          if (feedback) {
            await secured.register(feedbackRoutes, {
              verifier,
              users,
              conversations,
              feedback,
              analyzer,
              catalog,
              now,
              requireEmailVerification: config.requireEmailVerification,
            });
          }
        }
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
