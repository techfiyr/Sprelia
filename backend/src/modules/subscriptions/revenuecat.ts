import { timingSafeEqual } from 'node:crypto';

/**
 * RevenueCat REST (verified 2026-11-09, revenuecat.com/docs/api-v1/customers):
 * `GET https://api.revenuecat.com/v1/subscribers/{app_user_id}` with `Authorization: Bearer <key>`;
 * `subscriber.entitlements.<id>` has `expires_date` (null = no expiry) and
 * `grace_period_expires_date`; `product_identifier`; the subscription's `store` is under
 * `subscriber.subscriptions.<product>.store`. App user IDs must be URL-encoded.
 */
export interface EntitlementSnapshot {
  active: boolean;
  expiresAt: Date | null;
  productId: string | null;
  store: string | null;
}

export interface RevenueCatClient {
  getEntitlement(appUserId: string, entitlementId: string, now: Date): Promise<EntitlementSnapshot>;
}

const parseDate = (v: unknown) => (typeof v === 'string' && !Number.isNaN(Date.parse(v)) ? new Date(v) : null);

/** Pure: derives the current entitlement from a GET /v1/subscribers response body. */
export function entitlementFromSubscriber(body: unknown, entitlementId: string, now: Date): EntitlementSnapshot {
  const subscriber = (body as { subscriber?: Record<string, unknown> } | null)?.subscriber;
  const ent = (subscriber?.entitlements as Record<string, Record<string, unknown>> | undefined)?.[entitlementId];
  if (!ent) return { active: false, expiresAt: null, productId: null, store: null };
  const expires = parseDate(ent.expires_date);
  const grace = parseDate(ent.grace_period_expires_date);
  const effective = expires && grace && grace > expires ? grace : expires;
  const productId = typeof ent.product_identifier === 'string' ? ent.product_identifier : null;
  const subs = subscriber?.subscriptions as Record<string, Record<string, unknown>> | undefined;
  const store = productId && typeof subs?.[productId]?.store === 'string' ? (subs[productId]!.store as string) : null;
  // `expires_date: null` means no expiry (lifetime) per the docs' sample.
  const active = ent.expires_date === null || ent.expires_date === undefined ? true : !!effective && effective > now;
  return { active, expiresAt: effective, productId, store };
}

export class HttpRevenueCatClient implements RevenueCatClient {
  constructor(
    private readonly secretApiKey: string,
    private readonly baseUrl = 'https://api.revenuecat.com/v1',
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async getEntitlement(appUserId: string, entitlementId: string, now: Date): Promise<EntitlementSnapshot> {
    const res = await this.fetchImpl(`${this.baseUrl}/subscribers/${encodeURIComponent(appUserId)}`, {
      headers: { authorization: `Bearer ${this.secretApiKey}`, accept: 'application/json' },
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) throw new Error(`RevenueCat responded ${res.status}`);
    return entitlementFromSubscriber(await res.json(), entitlementId, now);
  }
}

/** Constant-time comparison of the webhook authorization value. */
export function safeEqual(a: string | undefined, b: string): boolean {
  if (typeof a !== 'string') return false;
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}
