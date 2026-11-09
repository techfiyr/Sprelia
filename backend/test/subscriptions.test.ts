import { describe, expect, it } from 'vitest';
import type { AIProvider } from '../src/modules/conversations/ai-provider.js';
import { GEMINI_LIVE_WS_URL } from '../src/modules/conversations/gemini-provider.js';
import { InMemoryConversationRepository } from '../src/modules/conversations/memory-conversation.repository.js';
import type { AuthenticatedUser, TokenVerifier } from '../src/modules/auth/token-verifier.js';
import { InMemorySubscriptionRepository } from '../src/modules/subscriptions/memory-subscription.repository.js';
import { entitlementFromSubscriber, safeEqual, type EntitlementSnapshot, type RevenueCatClient } from '../src/modules/subscriptions/revenuecat.js';
import { isEntitled } from '../src/modules/subscriptions/subscription.repository.js';
import { InMemoryUserRepository } from '../src/modules/users/memory-user.repository.js';
import { FakeVerifier, LogCapture, makeApp, testConfig, VALID_TOKEN } from './helpers.js';

const UID = 'AbCdEf1234567890XyZ1234567ab'; // Firebase-style UID (the RevenueCat app user ID)
const OTHER_UID = 'ZzYyXx0987654321WwVv7654321z';
const NOW = new Date('2026-11-09T10:00:00Z');
const WEBHOOK_AUTH = 'rc-webhook-shared-secret-0123456789abcdef';
const user: AuthenticatedUser = { uid: UID, email: 'p@example.com', emailVerified: true, signInProvider: 'password', authTime: 1 };

class Verifier implements TokenVerifier {
  async verify(token: string) {
    if (token === VALID_TOKEN) return user;
    return new FakeVerifier().verify(token);
  }
}

class FakeRevenueCat implements RevenueCatClient {
  states = new Map<string, EntitlementSnapshot>();
  calls: string[] = [];
  fail = false;
  async getEntitlement(appUserId: string) {
    this.calls.push(appUserId);
    if (this.fail) throw new Error('RevenueCat responded 500');
    return this.states.get(appUserId) ?? { active: false, expiresAt: null, productId: null, store: null };
  }
}

const premium = (days = 30): EntitlementSnapshot => ({
  active: true,
  expiresAt: new Date(NOW.getTime() + days * 86_400_000),
  productId: 'sprelia_premium_monthly:monthly',
  store: 'PLAY_STORE',
});

const fakeAI: AIProvider = {
  available: true,
  createRealtimeSession: async () => ({ provider: 'gemini', token: 'auth_tokens/t', model: 'gemini-3.8-live', websocketUrl: GEMINI_LIVE_WS_URL, expiresAt: NOW }),
};

async function setup(opts: { configured?: boolean; logs?: LogCapture } = {}) {
  const users = new InMemoryUserRepository();
  await users.createProfileIfAbsent({ uid: UID, email: 'p@example.com', displayName: null, timezone: 'UTC' });
  await users.saveOnboarding(
    UID,
    { interfaceLanguage: 'en', nativeLanguage: 'es', goals: ['career'], level: 'B2', dailyGoalMinutes: 15, accent: 'american' },
    true,
  );
  const subscriptions = new InMemorySubscriptionRepository(users);
  const revenueCat = new FakeRevenueCat();
  const configured = opts.configured ?? true;
  const app = await makeApp({
    config: testConfig(configured ? { REVENUECAT_WEBHOOK_AUTH: WEBHOOK_AUTH, REVENUECAT_SECRET_API_KEY: 'sk_test_not_real_key' } : {}),
    verifier: new Verifier(),
    users,
    subscriptions,
    revenueCat,
    conversations: new InMemoryConversationRepository(users),
    ai: fakeAI,
    now: () => NOW,
    logs: opts.logs,
  });
  const hook = (event: object, auth = WEBHOOK_AUTH) =>
    app.inject({ method: 'POST', url: '/api/v1/webhooks/revenuecat', headers: { authorization: auth }, payload: { api_version: '1.0', event } });
  const me = (url: string) => app.inject({ method: 'GET', url, headers: { authorization: `Bearer ${VALID_TOKEN}` } });
  return { app, subscriptions, revenueCat, hook, me };
}

const purchase = (extra: object = {}) => ({ id: 'evt-1', type: 'INITIAL_PURCHASE', app_user_id: UID, aliases: [UID], ...extra });

describe('RevenueCat webhook', () => {
  it('is not exposed unless both RevenueCat secrets are configured', async () => {
    const { hook } = await setup({ configured: false });
    expect((await hook(purchase())).statusCode).toBe(404);
  });

  it('rejects a missing or wrong authorization value', async () => {
    const { hook, revenueCat } = await setup();
    expect((await hook(purchase(), 'wrong')).statusCode).toBe(401);
    expect((await hook(purchase(), '')).statusCode).toBe(401);
    expect(revenueCat.calls).toEqual([]);
  });

  it('acknowledges TEST events', async () => {
    const { hook } = await setup();
    expect((await hook({ id: 't', type: 'TEST', app_user_id: 'test' })).json()).toEqual({ received: true });
  });

  it('a purchase grants Premium only after the REST API confirms it', async () => {
    const { hook, me, revenueCat } = await setup();
    revenueCat.states.set(UID, premium());
    const res = await hook(purchase());
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ received: true, updated: 1 });
    expect(revenueCat.calls).toEqual([UID]);
    expect((await me('/api/v1/me/subscription')).json().subscription).toMatchObject({
      plan: 'premium',
      store: 'PLAY_STORE',
      dailyAllowanceSeconds: 1800,
    });
  });

  it('never trusts the webhook body: REST says not entitled → stays free', async () => {
    const { hook, me } = await setup();
    await hook(purchase({ entitlement_ids: ['premium'], expiration_at_ms: NOW.getTime() + 1e10 }));
    expect((await me('/api/v1/me/subscription')).json().subscription.plan).toBe('free');
  });

  it('expiration revokes Premium; retries of the same event are harmless', async () => {
    const { hook, me, revenueCat } = await setup();
    revenueCat.states.set(UID, premium());
    await hook(purchase());
    revenueCat.states.set(UID, { active: false, expiresAt: new Date(NOW.getTime() - 1000), productId: 'p', store: 'PLAY_STORE' });
    await hook({ id: 'evt-2', type: 'EXPIRATION', app_user_id: UID });
    await hook({ id: 'evt-2', type: 'EXPIRATION', app_user_id: UID });
    expect((await me('/api/v1/me/subscription')).json().subscription.plan).toBe('free');
  });

  it('a RevenueCat outage returns 503 (RevenueCat retries) and writes nothing', async () => {
    const { hook, subscriptions, revenueCat } = await setup();
    revenueCat.fail = true;
    expect((await hook(purchase())).statusCode).toBe(503);
    expect(subscriptions.states.size).toBe(0);
  });

  it('ignores anonymous/non-Firebase IDs and users without a profile; TRANSFER refreshes both sides', async () => {
    const { hook, revenueCat, subscriptions } = await setup();
    const anon = await hook({ id: 'e', type: 'RENEWAL', app_user_id: '$RCAnonymousID:abc123', aliases: ['$RCAnonymousID:abc123'] });
    expect(anon.json().updated).toBe(0);
    expect(revenueCat.calls).toEqual([]);

    revenueCat.states.set(UID, premium());
    const transfer = await hook({ id: 'x', type: 'TRANSFER', transferred_from: [OTHER_UID], transferred_to: [UID] });
    expect(revenueCat.calls).toEqual([UID, OTHER_UID]);
    expect(transfer.json().updated).toBe(1); // OTHER_UID has no profile here
    expect(subscriptions.states.get(UID)?.lastEventId).toBe('x');
  });

  it('never logs secrets', async () => {
    const logs = new LogCapture();
    const { hook } = await setup({ logs });
    await hook(purchase(), 'wrong-secret-value');
    await hook(purchase());
    expect(logs.text).not.toContain(WEBHOOK_AUTH);
    expect(logs.text).not.toContain('wrong-secret-value');
  });
});

describe('Premium features use the server entitlement', () => {
  it('Premium scenarios, the higher allowance and the dashboard plan', async () => {
    const { hook, me, app, revenueCat } = await setup();
    const startPresentations = () =>
      app.inject({ method: 'POST', url: '/api/v1/me/conversations', headers: { authorization: `Bearer ${VALID_TOKEN}` }, payload: { tutorId: 'alex', scenarioId: 'presentations' } });
    expect((await startPresentations()).json().error.code).toBe('PREMIUM_REQUIRED');
    expect((await me('/api/v1/me/dashboard')).json().dashboard).toMatchObject({ plan: 'free', today: { freeAllowanceSeconds: 600 } });

    revenueCat.states.set(UID, premium());
    await hook(purchase());
    const started = await startPresentations();
    expect(started.statusCode).toBe(201);
    expect(started.json().allowedDurationSeconds).toBe(600); // capped per session; daily allowance is 1800
    expect((await me('/api/v1/me/dashboard')).json().dashboard).toMatchObject({ plan: 'premium', today: { freeAllowanceSeconds: 1800 } });
  });
});

describe('entitlement parsing (GET /v1/subscribers response)', () => {
  const body = (ent: object | undefined, store = 'PLAY_STORE') => ({
    subscriber: {
      entitlements: ent ? { premium: { product_identifier: 'sprelia_premium_monthly', ...ent } } : {},
      subscriptions: { sprelia_premium_monthly: { store } },
    },
  });
  it('active, expired, grace period, lifetime and missing', () => {
    expect(entitlementFromSubscriber(body({ expires_date: '2026-12-09T00:00:00Z' }), 'premium', NOW)).toMatchObject({ active: true, store: 'PLAY_STORE' });
    expect(entitlementFromSubscriber(body({ expires_date: '2026-11-01T00:00:00Z' }), 'premium', NOW).active).toBe(false);
    expect(
      entitlementFromSubscriber(body({ expires_date: '2026-11-08T00:00:00Z', grace_period_expires_date: '2026-11-12T00:00:00Z' }), 'premium', NOW).active,
    ).toBe(true);
    expect(entitlementFromSubscriber(body({ expires_date: null }), 'premium', NOW)).toMatchObject({ active: true, expiresAt: null });
    expect(entitlementFromSubscriber(body(undefined), 'premium', NOW).active).toBe(false);
    expect(entitlementFromSubscriber(null, 'premium', NOW).active).toBe(false);
  });
  it('isEntitled and constant-time comparison', () => {
    expect(isEntitled(null, NOW)).toBe(false);
    expect(isEntitled({ active: true, entitlementId: 'premium', expiresAt: new Date(NOW.getTime() - 1), productId: null, store: null, updatedAt: NOW, lastEventId: null }, NOW)).toBe(false);
    expect(safeEqual('abc', 'abc')).toBe(true);
    expect(safeEqual('abd', 'abc')).toBe(false);
    expect(safeEqual(undefined, 'abc')).toBe(false);
  });
  it('RevenueCat secrets are never serialized from config', () => {
    const c = testConfig({ REVENUECAT_WEBHOOK_AUTH: WEBHOOK_AUTH, REVENUECAT_SECRET_API_KEY: 'sk_test_not_real_key' });
    expect(c.revenueCatWebhookAuth).toBe(WEBHOOK_AUTH);
    expect(JSON.stringify(c)).not.toContain(WEBHOOK_AUTH);
    expect(JSON.stringify(c)).not.toContain('sk_test_not_real_key');
  });
});
