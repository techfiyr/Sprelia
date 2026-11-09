# Firebase setup and environment strategy

## Architecture decision: single Firebase project

**Status:** Approved by the project owner · **Date:** 2026-11-09 · Supersedes the earlier
strategy (production-only `sprelia` plus a separate `sprelia-dev` project).

| Environment | Firebase project | Used by |
|---|---|---|
| Local and automated tests | Firebase Emulator Suite, project `demo-sprelia` | Local development, CI, **all** automated tests |
| Development (pre-launch) | **`sprelia`** (number `756773147926`) | Development builds and a local backend, **test accounts and test data only** |
| Staging / production | **`sprelia`** | Deployed backend and release builds (not before the readiness checklist passes) |

Do not create another Firebase project. The app is not publicly released until
`doc/roadmap/phase_3.md` §5 (pre-release checklist) is complete.

Security requirements (binding; see also `.agents/security.md` §1a):
1. Automated tests never touch `sprelia`: they run only on the emulators and fail closed otherwise.
2. Manual checks on `sprelia` use clearly identified test accounts and test data only. Never run
   destructive scripts or tests against real user data.
3. Never deploy Firestore rules or change Firebase settings without explicit owner approval.
4. No service-account key files anywhere. Local backend access uses personal Application Default
   Credentials (`gcloud auth application-default login`). Keys and CI secrets stay out of git.
5. Verify the project ID before every deployment.
6. Separate Android and iOS Firebase app configurations (one app per platform in `sprelia`).
7. Development-only mechanisms (emulator hosts, App Check debug providers, the legacy prototype's
   `DEV_SKIP_AUTH`) never reach a release build or a deployed environment.

Enforced in code:
- Backend `loadConfig` (`backend/src/config/env.ts`): only `sprelia` or `demo-*` projects;
  staging/production must use `sprelia`; `APP_ENV=test` refuses any non-`demo-*` project; `demo-*`
  needs the emulators; emulator hosts are refused in staging/production; App Check must be
  `enforce` in production; email verification can't be disabled in staging/production.
- Flutter `AppConfig`: the same project rules; emulator only in development; App Check can only
  be turned off in development.
- Integration tests (`backend/test/integration/emulator-guard.ts`): abort before any test, and
  again before every wipe, unless both emulator hosts are local and every project variable is `demo-*`.

## Current status (read-only audit, 2026-11-09)

| Item | Status |
|---|---|
| Project `sprelia` | Exists, accessible |
| Android app `com.techfiyr.sprelia` | Registered (`1:756773147926:android:1bc8ce332ae6b5ccce2c37`). The owner-provided client config was verified locally (project and package match) and used for the gitignored `env/development-firebase.local.json` |
| Android SHA-1 / SHA-256 | **None** |
| iOS app | **Not registered** |
| Google provider | **Not enabled** (the Android config has no OAuth clients) |
| Email/Password provider, enumeration protection, email templates | **Not verifiable from the CLI**; owner to check |
| Firestore database | **Does not exist**; rules not deployed |
| App Check | **Not verifiable from the CLI**; assume not configured |
| Release signing | **None** (release builds are debug-signed and must not be distributed) |

## Owner actions (see `doc/roadmap/phase_3.md` §2 for the full list)
- Enable Email/Password (with email enumeration protection) and Google; send the Web and iOS
  OAuth client IDs.
- Register the iOS app; add the debug and, later, release and Play App Signing SHA fingerprints.
- Choose the Firestore region, create the database, approve deploying `firestore.rules`.
- App Check: Play Integrity (Play Console link), App Attest (Apple Team ID), debug tokens for test devices.
- Install `gcloud` for local Application Default Credentials.
- Confirm the account deletion and data retention policy (release blocker; see below).

## Flutter wiring
- `firebase_core`, `firebase_auth`, `firebase_app_check`, `google_sign_in`. Options come from
  dart-defines through `AppConfig.firebase`, per platform (Android values; iOS values once the iOS
  app is registered). No `google-services.json`, `GoogleService-Info.plist` or FlutterFire options
  file is read or committed (decision D6, recommended, not yet confirmed).
- `env/development.json`: emulators (`demo-sprelia`).
  `env/development-firebase.local.json` (gitignored): the shared `sprelia` project.
- Google sign-in is enabled automatically when `GOOGLE_SERVER_CLIENT_ID` (and on iOS
  `GOOGLE_IOS_CLIENT_ID`) is set. iOS also needs the reversed client ID URL scheme in `Info.plist`.
- App Check: Play Integrity / App Attest in release builds, debug providers in debug builds, never
  with the emulator. The token is sent as `X-Firebase-AppCheck`.

## Backend wiring
- `FIREBASE_PROJECT_ID` selects the project whose ID tokens are accepted (checked at startup).
- Credentials: Application Default Credentials (the Cloud Run service account when deployed). No key files.
- Local with emulators: `firebase emulators:start --only auth,firestore --project demo-sprelia`
  with `FIREBASE_AUTH_EMULATOR_HOST` and `FIRESTORE_EMULATOR_HOST`.
- `APP_CHECK_MODE` (`off` / `monitor` / `enforce`), `REQUIRE_EMAIL_VERIFICATION`,
  `RECENT_AUTH_MAX_AGE_SECONDS` (account deletion).

## Account deletion and data retention
`DELETE /api/v1/me` currently performs an **immediate hard delete** (all of `users/{uid}`, then the
Auth user). This is the engineering **recommendation (D2), not an owner-approved policy**.
APP_FLOW §17 requires deletion "according to the published retention policy and applicable legal
requirements"; that policy does not exist yet. **Release blocker:** the owner (with legal input)
must confirm the deletion behavior and publish the retention policy before public release.

## Security rules
`firestore.rules` is a protected file and was not changed in Phase 3. It denies all client access,
verified by `backend/test/integration/firestore.rules.test.ts`. Keeping API-only access is
recommended (D4, not yet confirmed). Its header comment still says "Phase 4"; updating that comment
needs owner approval. The rules are not deployed (no Firestore database exists).
