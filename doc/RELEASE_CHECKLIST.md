# Sprelia release checklist (Phase 10)

Status 2026-11-09: the app and API features in Phases 3–9 are implemented and verified locally
(emulators, unit and widget tests, live Gemini checks). **The app is not release-ready**: the items
below need owner accounts, decisions or approvals. Nothing has been deployed or published.

## A. Verified locally (re-run before every release)
| Check | Command |
|---|---|
| Flutter static analysis | `flutter analyze` |
| Flutter unit/widget tests (incl. branding, spelling, assets) | `flutter test` |
| Backend typecheck, unit tests, build | `cd backend && npm run typecheck && npm test && npm run build` |
| Emulator integration (API + Firestore rules, `demo-sprelia` only, fail-closed guard) | `cd backend && npm run test:integration` |
| Live provider checks (opt-in; key from the gitignored root `.env`) | `cd backend && npm run test:live` |
| Debug APK (emulator config) | `flutter build apk --debug --dart-define-from-file=env/development.json` |
| Secret scan of the diff | see `.agents/development.md` |

## B. Owner actions (blocking release)
**Firebase / Google Cloud**
- [ ] Deploy the deny-all `firestore.rules` to `sprelia` (approval); confirm the rules currently active
- [ ] Enable delete protection and point-in-time recovery on Firestore (recommended)
- [ ] Email/Password with enumeration protection; email templates and sender name
- [ ] Google sign-in provider; Web + iOS OAuth client IDs into the app config; iOS URL scheme
- [ ] Register the iOS app; add release and Play App Signing SHA-1/SHA-256
- [ ] App Check: Play Integrity (Play Console link), App Attest; then `APP_CHECK_MODE=enforce`
- [ ] Create a dedicated least-privilege service account for Netlify and rotate `sprelia-c6a0682eb252`
- [ ] FCM setup for practice reminders (opt-in is stored; delivery not built)

**Hosting (Netlify)**
- [ ] Connect the site, set the environment variables (`doc/DEPLOYMENT_NETLIFY.md`), deploy with approval
- [ ] Verify the RevenueCat webhook authorization header name with a real delivery

**Signing and stores**
- [ ] Release keystore stored as a CI secret; Gradle release `signingConfig` from `key.properties`
      (protected file `android/app/build.gradle.kts`: needs approval; release builds are debug-signed today)
- [ ] Google Play Console app, store listing, content rating, data safety form
- [ ] Apple developer account (iOS later); Sign in with Apple decision (D7)

**Monetization**
- [ ] RevenueCat project, Play subscription products/base plans, entitlement `premium`, keys;
      add `purchases_flutter` and `Purchases.logIn(firebaseUid)`
- [ ] Final prices, trials, refunds; Premium daily allowance (`PREMIUM_DAILY_SECONDS`)
- [ ] AdMob account, ad unit IDs, consent (UMP), ad personalization decision; add `google_mobile_ads`

**Legal and policy**
- [ ] Operator, contacts, jurisdiction, effective dates on the website drafts (`doc/reviews/LEGAL_PAGES_REVIEW.md`)
- [ ] Data retention policy: account deletion behavior (D2) and transcript retention period
- [ ] Age confirmation approach (18+)
- [ ] Legal review; then remove `noindex` and the `robots.txt` block
- [ ] Brand clearance for "Sprelia" (trademark, domain, store name); final logo and tutor images with rights

**Content**
- [ ] Human review of the 27 practice scenarios (production serves approved scenarios only; all are drafts)

## C. Engineering follow-ups (not blocking a closed test, recommended before public launch)
- Remove the legacy Express prototype (`backend/src/server.ts`, `config.ts`, `tokens.ts`, `usage.ts`,
  `analysis.ts`, `tutors.ts`) and the app's `DEV_USER_ID` header: superseded by the Phase 6–8
  modules. Deleting files needs owner approval.
- Distributed rate limiting (in-memory limits are per Netlify function instance).
- `npm audit`: 4 moderate transitive advisories (`minimatch`/`rimraf` via `google-gax`); `npm audit fix`
  is blocked by npm's install-script approval policy here. Re-check after dependency updates.
- Real-device voice test (microphone, echo cancellation, playback, interruptions); session
  resumption if sessions longer than ~10 minutes are wanted.
- Interface language switching (only English ships); Crashlytics/Analytics (planned, consent needed).
