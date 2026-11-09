# Phase 9: Premium, subscriptions and ads

**Status:** `[/]` Everything that does not need external accounts is implemented and verified
locally (2026-11-09). Real purchases and ads are blocked on owner items (below).

## Verified provider facts (RevenueCat docs, 2026-11-09)
- Webhook: optional authorization value sent with every POST; respond 200 (otherwise up to 5
  retries over ~80 min); make processing idempotent (event `id` repeats on retries).
- RevenueCat recommends calling `GET https://api.revenuecat.com/v1/subscribers/{app_user_id}`
  (`Authorization: Bearer <key>`) after any webhook; entitlement expiry at
  `subscriber.entitlements.<id>.expires_date` (null = no expiry), grace period at
  `grace_period_expires_date`.
- `SUBSCRIPTION_PAUSED` must not revoke access; `TRANSFER` lists `transferred_from` / `transferred_to`.
- Custom app user IDs (our Firebase UID) are allowed. **To verify with a real delivery:** the docs
  do not name the HTTP header carrying the authorization value; the backend assumes `Authorization`.

## Implemented
| Part | Implementation |
|---|---|
| Entitlement store | `users/{uid}/subscription/current`, written only by the backend (existing profiles only); client rules deny it |
| Webhook | `POST /api/v1/webhooks/revenuecat`: constant-time auth, body never trusted, REST re-read per affected UID (idempotent), 503 on RevenueCat outage so it retries, anonymous IDs ignored, secrets non-enumerable and redacted |
| Premium checks | Premium scenarios, Premium daily allowance (placeholder `PREMIUM_DAILY_SECONDS=1800`), dashboard `plan` and recommendations all use the server entitlement |
| `GET /me/subscription` | Plan, expiry, store, daily allowance |
| App | Paywall (`/premium`) with APP_FLOW §16 benefits, the documented test prices marked "not final", disabled purchase/restore until configured; entry points: Premium-locked scenario, daily limit reached, Profile → Subscription |
| Ads | Placement policy (`adAllowed`): free plan only, never in a conversation or on the paywall; `AdService` unavailable, so nothing is loaded or shown |

## Blocked (owner)
- RevenueCat project, Google Play subscription products and base plans, entitlement `premium`,
  public SDK key (app) and secret key + webhook authorization value (backend secrets); then add
  the `purchases_flutter` SDK and `Purchases.logIn(firebaseUid)`.
- Pricing (test prices only), trial and refund policy; Premium daily allowance.
- AdMob account, app ID and ad unit IDs, consent (UMP) and ad personalization decision; then the
  `google_mobile_ads` SDK.

## Verification
| Check | Result |
|---|---|
| Backend unit | All pass (new `test/subscriptions.test.ts`, 13 tests) |
| Emulator integration | All pass (new: webhook → stored entitlement → Premium plan; no orphan documents) |
| Flutter | All pass (new `test/features/premium_test.dart`, 5 tests) |
