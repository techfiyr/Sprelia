import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, ErrorCode } from '../../common/errors.js';
import { authenticate, requireUser } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import { safeEqual, type RevenueCatClient } from './revenuecat.js';
import { isEntitled, type SubscriptionRepository } from './subscription.repository.js';

/** Firebase UIDs (the RevenueCat app user ID is the Firebase UID, APP_DEVELOPMENT §11). */
const FIREBASE_UID = /^[A-Za-z0-9]{20,128}$/;

const WebhookBody = z
  .object({
    api_version: z.string().optional(),
    event: z
      .object({
        id: z.string().min(1).max(200),
        type: z.string().min(1).max(64),
        app_user_id: z.string().max(200).nullish(),
        original_app_user_id: z.string().max(200).nullish(),
        aliases: z.array(z.string().max(200)).max(100).nullish(),
        transferred_from: z.array(z.string().max(200)).max(100).nullish(),
        transferred_to: z.array(z.string().max(200)).max(100).nullish(),
      })
      .passthrough(),
  })
  .passthrough();

export interface RevenueCatWebhookOptions {
  webhookAuth: string;
  client: RevenueCatClient;
  subscriptions: SubscriptionRepository;
  entitlementId: string;
  now: () => Date;
}

/**
 * RevenueCat webhook (verified docs 2026-11-09): the configured authorization value is sent with
 * every POST; respond 200 (anything else is retried up to 5 times). The webhook body is never
 * trusted for entitlement state: for every affected user the backend re-reads the current state
 * from the RevenueCat REST API (`GET /v1/subscribers/{id}`, as RevenueCat recommends) and stores
 * it. That makes processing idempotent for retries and out-of-order events.
 */
export const revenueCatWebhookRoutes: FastifyPluginAsync<RevenueCatWebhookOptions> = async (app, opts) => {
  app.post('/webhooks/revenuecat', async (request, reply) => {
    // Assumption to verify with a real delivery: the value arrives in the HTTP Authorization header.
    if (!safeEqual(request.headers.authorization, opts.webhookAuth)) {
      throw new AppError(401, ErrorCode.UNAUTHENTICATED, 'Authentication required.');
    }
    const parsed = WebhookBody.safeParse(request.body);
    if (!parsed.success) throw new AppError(400, ErrorCode.VALIDATION_ERROR, 'The request is invalid.');
    const event = parsed.data.event;
    if (event.type === 'TEST') return reply.status(200).send({ received: true });

    const candidates =
      event.type === 'TRANSFER'
        ? [...(event.transferred_to ?? []), ...(event.transferred_from ?? [])]
        : [event.app_user_id, event.original_app_user_id, ...(event.aliases ?? [])];
    const uids = [...new Set(candidates.filter((id): id is string => typeof id === 'string' && FIREBASE_UID.test(id)))];

    let updated = 0;
    for (const uid of uids) {
      const now = opts.now();
      let snapshot;
      try {
        snapshot = await opts.client.getEntitlement(uid, opts.entitlementId, now);
      } catch {
        // RevenueCat will retry the webhook; nothing is written from the untrusted body.
        throw new AppError(503, ErrorCode.SERVICE_UNAVAILABLE, 'Service temporarily unavailable. Please try again.');
      }
      const written = await opts.subscriptions.set(uid, {
        ...snapshot,
        entitlementId: opts.entitlementId,
        updatedAt: now,
        lastEventId: event.id,
      });
      if (written) updated++;
    }
    request.log.info({ eventType: event.type, candidates: uids.length, updated }, 'revenuecat webhook processed');
    return reply.status(200).send({ received: true, updated });
  });
};

export interface SubscriptionRoutesOptions {
  verifier: TokenVerifier;
  subscriptions: SubscriptionRepository;
  now: () => Date;
  freeDailySeconds: number;
  premiumDailySeconds: number;
}

/** GET /me/subscription: the server-verified plan (the app never decides entitlement itself). */
export const subscriptionRoutes: FastifyPluginAsync<SubscriptionRoutesOptions> = async (app, opts) => {
  app.get('/me/subscription', { preHandler: authenticate(opts.verifier) }, async (request, reply) => {
    const { uid } = requireUser(request);
    const state = await opts.subscriptions.get(uid);
    const premium = isEntitled(state, opts.now());
    reply.header('cache-control', 'private, no-store');
    return {
      subscription: {
        plan: premium ? 'premium' : 'free',
        expiresAt: premium ? (state?.expiresAt?.toISOString() ?? null) : null,
        store: premium ? (state?.store ?? null) : null,
        dailyAllowanceSeconds: premium ? opts.premiumDailySeconds : opts.freeDailySeconds,
      },
    };
  });
};
