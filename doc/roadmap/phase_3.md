# Phase 3: Firebase integration and account management

**Status:** `[/]` **Code complete and verified locally (emulators only); NOT complete.** Blocked
by owner-only Firebase, signing and policy items (§2, §3, §5). Not committed: completion requires
those blockers to be resolved (owner instruction). Verification results: §8.
**Last updated:** 2026-11-09 · **Branch:** `main` (owner decision: work directly on `main`)

## Approved architecture decision: single Firebase project (2026-11-09)

| | |
|---|---|
| Project name | Sprelia |
| Project ID | `sprelia` |
| Project number | `756773147926` |

- The owner confirmed this project exists. It is used for **development**, **integration testing
  where appropriate**, and **eventual production**.
- **Do not create another Firebase project.** This supersedes the earlier proposal for a separate
  `sprelia-dev` project (Phase 2 close-out, `doc/FIREBASE_SETUP.md`).
- The app is **not publicly deployed or released** until development, testing, security review
  and production readiness are complete.
- Automated tests still run on the Firebase Emulator Suite (`demo-sprelia`). Manual or
  integration checks against `sprelia` use only clearly identified test accounts and test data.
  Never run destructive tests against real user data.

## 1. Read-only audit (2026-11-09)

Method: `firebase` CLI 15.34.0, signed in as the project's account, read-only commands only
(`projects:list`, `apps:list`, `apps:sdkconfig`, `apps:android:sha:list`,
`firestore:databases:list`), plus inspection of the repository. Nothing was created, changed,
deployed or deleted. The CLI cannot read Auth provider or App Check settings. A direct read-only
REST call for them was blocked by the local permission policy, so those items are marked
**not verifiable from here** and need a Console check by the owner.

| Area | Finding | Status |
|---|---|---|
| Project | `sprelia` / 756773147926, display name "Sprelia", accessible | Configured |
| Android app | `1:756773147926:android:1bc8ce332ae6b5ccce2c37`, package **`com.techfiyr.sprelia`** (matches `android/app/build.gradle.kts`) | Configured |
| Android SHA-1 / SHA-256 | **None registered** | Missing |
| iOS app | **None registered**. Xcode bundle ID is `com.techfiyr.sprelia` | Missing |
| Web app | None (not needed) | n/a |
| OAuth clients in the Android config | `oauth_client: []`, so **Google sign-in is not enabled** (enabling it creates a web OAuth client) | Missing |
| Auth: Email/Password | Not verifiable from the CLI | Owner to check |
| Auth: email enumeration protection, templates, authorized domains | Not verifiable from the CLI | Owner to check |
| Firestore database | **No database exists**, so no rules are deployed | Missing |
| Firestore rules (repo) | `firestore.rules`: default deny for all clients; tested on the emulator | Ready, not deployed |
| App Check | Not verifiable from the CLI. Play Integrity needs a Play Console link; App Attest needs an Apple Team ID | Assume not configured |
| Config files in the repo | None committed (correct): no `google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options*.dart` or `.firebaserc`; all gitignored | OK |
| `firebase.json` | Firestore rules/indexes and emulators (Auth 9099, Firestore 8180, UI 4000) | OK |
| FlutterFire CLI / gcloud | **Not installed** | Needed only for the options below |
| Flutter Firebase wiring | `firebase_core` 5.1 + `firebase_auth` 7.0, options from dart-defines (`AppConfig.firebase`); Auth emulator in development | OK |
| Flutter config guard | `AppConfig` **refuses `sprelia` outside `APP_ENV=production`**. This conflicts with the new decision and must change | To change |
| Backend Admin SDK | `firebase-admin` 14.5; Application Default Credentials (no key files); Auth + Firestore emulators via env; `verifyIdToken(checkRevoked)` | OK |
| Backend config guard | `loadConfig` **refuses `sprelia` outside `APP_ENV=production`**. Conflicts with the new decision | To change |
| Debug signing key (this machine) | SHA-1 `8E:76:8A:6F:49:CB:11:E9:16:6C:3C:B3:DB:D4:B8:7D:A7:9F:D8:9A`, SHA-256 `B3:EA:58:51:7F:4C:BE:79:2E:35:8C:51:05:1C:DC:CC:3D:79:C4:78:5C:56:B3:E0:DA:96:1E:E5:8B:2B:2F:FB` | Available to register |
| Release signing | **None**: the `release` build type signs with the debug key. There is no release keystore and no Play App Signing | Missing (owner) |

Already implemented (Phases 1–2) and kept: email/password registration and login, password
reset (non-enumerating), logout, Firebase session persistence, backend ID-token verification on
every protected route, server-side profile and preferences in Firestore (native language,
level, goals, daily target, accent, interface language) through the API only, strict Zod
validation, and a uid always taken from the verified token.

## 2. Actions that need the owner

| # | Action | Who | Why it needs you |
|---|---|---|---|
| O1 | Approve this plan | Owner | Required before any change |
| O2 | Register the iOS app `com.techfiyr.sprelia` | Agent with approval (`firebase apps:create IOS`) | Creates a Firebase resource |
| O3 | Add the **debug** SHA-1/SHA-256 above to the Android app | Agent with approval (`firebase apps:android:sha:create`) | Modifies the Firebase app |
| O4 | Create the **release keystore**, keep it out of git (CI secret), and provide the release and Play App Signing SHA-1/SHA-256 | Owner | Signing material never goes through the agent |
| O5 | Enable **Email/Password** and **email enumeration protection**; set the sender name and action URL for the verification and reset emails | Owner (Console) | Not possible from the CLI |
| O6 | Enable the **Google** provider (with a support email); then share the generated **Web client ID** (used as `serverClientId`) and the **iOS client ID** / reversed client ID | Owner (Console) | Creates OAuth clients |
| O7 | **Create the Firestore database**: choose the **region** (permanent), Standard edition, production mode (deny all) | Owner decides; agent or owner creates | Permanent and billable |
| O8 | Approve deploying `firestore.rules` (default deny) to `sprelia` | Agent with approval (`firebase deploy --only firestore:rules --project sprelia`) | Deployment |
| O9 | App Check: register **Play Integrity** (link Play Console) and **App Attest** (Apple Team ID); approve registering debug tokens for test devices; keep enforcement **off** until release | Owner (Console) | Needs Play/Apple accounts |
| O10 | Local backend credentials for `sprelia`: install `gcloud` and run `gcloud auth application-default login` (no key files) | Owner | Personal credentials |
| O11 | Name the test-account convention (proposed: `qa+<name>@<your domain>`) and who may create them | Owner | Shared project hygiene |

## 3. Decisions needed

| # | Decision | Recommendation |
|---|---|---|
| D1 | Email verification enforcement | Password accounts must verify before onboarding or using the app (verification screen with resend, refresh and sign out). The backend also rejects unverified **password** accounts on `/me/*` writes and the dashboard. Google accounts arrive verified |
| D2 | Account deletion policy (APP_FLOW §17: "according to the published retention policy") | **Immediate hard delete** of `users/{uid}` and all subcollections, then the Auth user. No grace period for the MVP. Requires a sign-in within the last 5 minutes. **Implemented as the recommendation; NOT confirmed by the owner.** The published retention policy is a **release blocker** |
| D3 | Firestore region | Owner choice. Pick it close to the main audience and the future Cloud Run region (for example, `asia-south1` for South Asia) |
| D4 | Client Firestore access | **Keep default deny** (API-only architecture). Ownership is enforced by the backend. Owner-read rules are added only when the app needs a direct read |
| D5 | App Check rollout | Backend mode `off` / `monitor` / `enforce`. Development: monitor. Enforce before public release only |
| D6 | FlutterFire configuration | **Keep the dart-define approach** (no generated files, iOS values added). Alternative: `flutterfire configure` with all outputs gitignored (needs the CLI installed) |
| D7 | Sign in with Apple | Out of scope here, but **App Store Guideline 4.8** generally requires an equivalent option when Google sign-in is offered on iOS. Decide before the iOS release |

## 4. Implementation plan (after approval)

Incremental and on `main`. Every step keeps `flutter analyze`, `flutter test`, `npm run typecheck`,
`npm test` and the emulator suite green. Protected files touched (approved by this Phase 3 scope):
`backend/src/config/env.ts`, `backend/src/modules/auth/*`, `lib/core/auth/*`,
`lib/core/config/app_config.dart`, `sessionRedirect`, `ios/Runner/Info.plist`, `firestore.rules`
(no weakening).

1. **Environment guards (single project).** Allow `sprelia` in `development` and `staging`.
   Production must still be `sprelia`, and emulator hosts stay development-only. Automated tests
   refuse any project except `demo-*`. Development builds against `sprelia` show a small
   "Pre-launch build" marker. Update tests, `env/README.md`, `env/*.example.json` and
   `doc/FIREBASE_SETUP.md`.
2. **Firebase configuration.** Add iOS options (`FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID`)
   and Google client IDs to `AppConfig`; per-platform `FirebaseOptions`;
   `env/development-sprelia.local.json` (gitignored). Needs O2, O3 and O6.
3. **Google sign-in** (`google_sign_in` 7.2.0, API verified from the package source:
   `GoogleSignIn.instance.initialize(...)`, `authenticate()`, `authentication.idToken` →
   `GoogleAuthProvider.credential`). Sign-out also signs out of Google. iOS URL scheme in
   `Info.plist`. Friendly error mapping, including cancel.
4. **Email verification.** `sendEmailVerification`, reload, a verification screen (resend with a
   cooldown, "I've verified", sign out), a router gate in `sessionRedirect`, and the backend check
   from D1.
5. **Account deletion.** `DELETE /api/v1/me`: verified token, `auth_time` within 5 minutes
   (otherwise `REAUTH_REQUIRED`), recursive delete of `users/{uid}`, then `auth.deleteUser(uid)`,
   idempotent and logged without PII. App: Profile → Delete account → confirm → re-authenticate
   (password or Google) → delete → sign out.
6. **Session.** Persistence stays Firebase's default. Add explicit restore and expiry handling
   (revoked or disabled user → signed out with a message).
7. **App Check.** `firebase_app_check` 0.5.1 (`activate(providerAndroid: AndroidPlayIntegrityProvider
   / AndroidDebugProvider, providerApple: AppleAppAttestProvider / AppleDebugProvider)`, `getToken`),
   sending the `X-Firebase-AppCheck` header from Dio. Backend `verifyToken` (to be verified
   against the installed `firebase-admin` source) with `APP_CHECK_MODE`. Never enforced in tests;
   enforce is required for production by config before release.
8. **Firestore.** No new client paths. Keep default-deny rules and extend the rules tests
   (unauthenticated, other-user and own-user client access all denied). Deploy after O7 and O8.
9. **Tests.** Emulator integration: registration, login, invalid credentials, verification
   (emulator out-of-band codes), password reset, Google sign-in (emulator fake IdP credential),
   token revocation, deletion (data and Auth user gone, other users untouched), data isolation,
   unauthorized Firestore access, `REAUTH_REQUIRED`. Unit: App Check modes and config guards.
   Flutter: widget tests for Google, verification, deletion and restore flows, using fakes.
10. **Docs and report.** Roadmap, `FIREBASE_SETUP.md`, `.agents/*`, the release checklist below,
    and the final report. Then stop before Phase 4.

Excluded (later phases): Gemini live voice, AI feedback, RevenueCat, AdMob, store submissions,
public deployment.

## 5. Pre-release checklist (carried to the release phase)
- [ ] **Owner confirms the account deletion behavior (D2) and publishes the data retention policy** (APP_FLOW §17; legal input). Immediate hard delete is implemented only as the recommendation
- [ ] Google sign-in button artwork follows Google's branding guidelines (licensed asset in the asset library); a generic icon is used for now
- [ ] Review and remove test accounts and test data in `sprelia`
- [ ] Verify the production Firestore rules (deployed version = tested version)
- [ ] Verify App Check enforcement (Auth, Firestore, backend `APP_CHECK_MODE=enforce`)
- [ ] Verify the Android (release + Play App Signing SHAs) and iOS app registrations
- [ ] Verify the backend production configuration (project ID check before deploy)
- [ ] Confirm no development-only authentication bypasses remain (`DEV_SKIP_AUTH` prototype, emulator hosts, debug App Check providers)
- [ ] Final security review

## 6. Risks
- One shared project: a development mistake can affect real data after launch. Mitigations: test
  accounts only, automated tests on the emulators, deletion limited to the caller's own uid,
  App Check, and the pre-release cleanup.
- No release keystore: release builds are debug-signed and must not be distributed.
- The legacy Express prototype (`DEV_SKIP_AUTH`) must never run against `sprelia`.
- Sign in with Apple (D7) may block the iOS release.

## 7. Implementation record (2026-11-09, verified locally)

Recommended answers were used where an owner decision is still open (D1, D2, D4–D6); each is
marked in code and docs as a recommendation, not an approval.

| Plan step | Done locally | Notes / blockers |
|---|---|---|
| 1. Environment guards | `[x]` Backend `env.ts` and Flutter `AppConfig`: only `sprelia` or `demo-*`; staging/production must use `sprelia`; `APP_ENV=test` refuses real projects; `demo-*` needs the emulators. Integration suite fails closed (`test/integration/emulator-guard.ts`, `setup.ts`). Docs reconciled | `firestore.rules` (protected) left unchanged, so its header comment still says "Phase 4" |
| 2. Firebase configuration | `[/]` Per-platform `FirebaseOptions` from dart-defines; iOS and Google keys in `AppConfig`; the owner's Android config verified (project and package match) and turned into the gitignored `env/development-firebase.local.json` | iOS app not registered (F1); no SHAs (F2, O3); the iOS `Info.plist` URL scheme needs the reversed iOS client ID (O2) |
| 3. Google sign-in | `[x]` code: `google_sign_in` 7.2.0 → `GoogleAuthProvider.credential` → Firebase; welcome and sign-in buttons; sign-out also signs out of Google; cancel handled | **Disabled until O2** (no OAuth clients exist) |
| 4. Email verification and reset | `[x]` Verification sent at sign-up; `/verify-email` screen (resend with a 60 s cooldown, check, switch account); router gate; backend `EMAIL_NOT_VERIFIED` (403) for unverified password accounts on `/me/profile`, `/me/onboarding`, `/me/dashboard`. Reset stays non-enumerating | Needs O1 (provider and templates) on `sprelia` |
| 5. Session restore and logout | `[x]` `userChanges()` stream plus a manual emit after reload; a 401 on restore signs out locally | |
| 6. Account deletion | `[x]` `DELETE /api/v1/me` (recent sign-in ≤ `RECENT_AUTH_MAX_AGE_SECONDS`, else `REAUTH_REQUIRED` 403; recursive Firestore delete, then Auth delete; idempotent); app flow: confirm → re-auth (password or Google) → delete → clear local draft → sign out | **D2 unconfirmed; retention policy is a release blocker** |
| 7. Profile and onboarding persistence | `[x]` unchanged (server-written, validated) | |
| 8. Token checks and App Check | `[x]` ID-token check unchanged. App Check: `firebase_app_check` 0.5.1 client (debug and Play Integrity / App Attest), `X-Firebase-AppCheck` header; backend `appCheckGuard` with `APP_CHECK_MODE` (production must be `enforce`) | Needs O4/F5 before tokens validate |
| 9. Firestore ownership | `[x]` no client paths; rules unchanged (default deny) | Database and deploy: F3/F4 |
| 10. Tests | `[x]` Unit, widget and emulator integration tests added and passing | §8 |

## 8. Verification (2026-11-09, local only)

Live project `sprelia` was never contacted. Tests ran only on the local `demo-sprelia` emulators.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 129/129 (new `test/features/account_test.dart`: verification gate, resend cooldown, Google enabled/disabled/cancel/failure, session restore after server rejection, deletion success/cancel/Google re-auth/wrong password/`REAUTH_REQUIRED`; `app_config_test.dart` updated for the single-project rules) |
| Backend `npm run typecheck` | Pass |
| Backend `npm test` | 158/158 (new `test/account.test.ts`: verification gate, `DELETE /me`, App Check off/monitor/enforce; `test/emulator-guard.test.ts`; config tests) |
| Backend `npm run build` | Pass |
| `npm run test:integration` | 22/22 on the emulators: registration and login, invalid credentials, email verification with real out-of-band codes, password reset, Google sign-in (emulator fake IdP), `REAUTH_REQUIRED`, deletion (all Firestore paths and the Auth user gone; old token rejected; other users untouched), data isolation, revocation, rules |
| Emulator guard | Refuses runs without local emulators and with any non-`demo-*` project (`GCLOUD_PROJECT=sprelia` checked). It caught a non-demo `GOOGLE_CLOUD_PROJECT` in the local shell; `npm run test:integration` now pins it to `demo-sprelia` |
| Debug APK | Built with `env/development.json` (emulator, `demo-sprelia`); no Firebase config files or real keys in the APK |
| Secret scan (full diff, 60 files) | No keys, private keys, OAuth secrets or forbidden files |

Notes:
- The build warns that `firebase_core`, `firebase_auth` and `firebase_app_check` apply the Kotlin
  Gradle Plugin (a plugin migration notice; not a failure).
- Auth state now follows `userChanges()`, which also emits on token refresh, so the profile is
  re-read about hourly. Harmless, but can be narrowed later.
- Not verifiable locally: real Google sign-in (needs O2), App Check tokens (O4/F5), Firestore on
  `sprelia` (F3/F4), email templates and enumeration protection (O1), and iOS (F1, `Info.plist`).
