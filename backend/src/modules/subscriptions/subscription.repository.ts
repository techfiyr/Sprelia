/** users/{uid}/subscription/current: written by the backend only (RevenueCat webhook + REST). */
export interface SubscriptionState {
  active: boolean;
  entitlementId: string;
  /** null = no expiry (lifetime) or not entitled. */
  expiresAt: Date | null;
  productId: string | null;
  store: string | null;
  updatedAt: Date;
  /** RevenueCat event that triggered the last refresh (idempotency/audit). */
  lastEventId: string | null;
}

export interface SubscriptionRepository {
  get(uid: string): Promise<SubscriptionState | null>;
  /** Writes only if the user's profile exists; returns false otherwise. */
  set(uid: string, state: SubscriptionState): Promise<boolean>;
}

/** Premium only with an active, unexpired, server-verified entitlement. Never client-supplied. */
export function isEntitled(state: SubscriptionState | null, now: Date): boolean {
  return !!state?.active && (state.expiresAt === null || state.expiresAt > now);
}
