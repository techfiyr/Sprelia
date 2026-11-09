# Firebase setup and environment strategy

## Architecture decision: Firebase environment strategy

**Status:** Approved by the project owner · **Date:** 2026-11-09 · Final unless the owner changes it.

| Environment | Firebase project | Used by |
|---|---|---|
| **Production** | **`sprelia`** (project number `756773147926`) | Production app builds (`APP_ENV=production`) and the production API only |
| Development | Separate project, **not created yet** (proposed ID `sprelia-dev`; creation needs owner approval of the ID) | Development builds against a real project |
| Local and automated tests | Firebase Emulator Suite, project `demo-sprelia` | Local development, CI, all automated tests |

Security requirements (binding; see also `.agents/security.md` §1a):
1. Never use production credentials in local development.
2. Never run automated tests against production data. All tests use the emulators (`demo-sprelia`).
3. Never deploy Firestore rules or Firebase configuration to production without explicit approval.
4. Keep development and production environment variables separate.
5. Keep production credentials and service-account keys out of git.
6. Verify the Firebase project ID before every deployment.
7. Use separate Android and iOS Firebase app configurations for each environment.

Enforced in code:
- The backend `loadConfig` refuses `FIREBASE_PROJECT_ID=sprelia` unless `APP_ENV=production`,
  and refuses any other project in production (`PRODUCTION_FIREBASE_PROJECT_ID`).
- The Flutter `AppConfig` applies the same rule to builds (`productionFirebaseProjectId`).
- Emulator hosts and `demo-*` projects are refused outside development.
- `npm run test:integration` always runs with `--project demo-sprelia`.

## Current status (verified read-only, 2026-11-09)

| Item | Production `sprelia` | Development project |
|---|---|---|
| Project | Exists | **Not created** |
| Android app `com.techfiyr.sprelia` | Registered (`1:756773147926:android:1bc8ce332ae6b5ccce2c37`) | n/a |
| Android SHA-1 / SHA-256 fingerprints | **None** | n/a |
| iOS app `com.techfiyr.sprelia` | **Not registered** | n/a |
| Email/Password provider | **Not verified** (not configured by the agent) | n/a |
| Firestore database and rules | **Not verified / not deployed** | n/a |
| App Check | **Not configured** | n/a |

No production setting, data or credential was created or changed during Phases 1–2.

## Outstanding Firebase work

Phase 3 prepares these as a reviewed plan. Nothing is changed in production until the
Phase 3 plan and the proposed changes are approved.

**Production (`sprelia`):**
- [ ] Verify the Android app registration (package `com.techfiyr.sprelia`)
- [ ] Register the iOS app (bundle `com.techfiyr.sprelia`)
- [ ] Add Android SHA-1/SHA-256 fingerprints (release signing key and Play App Signing key)
- [ ] Enable the Email/Password provider (with email enumeration protection)
- [ ] Create the Firestore database (needs a region decision), then deploy production security rules after emulator tests
- [ ] Configure App Check (Play Integrity, App Attest), starting in monitor mode
- [ ] Validate the production configuration and deployment (project ID check before deploy)

**Development / environment separation:**
- [ ] Create the development project (proposed `sprelia-dev`) and register its Android and iOS apps
- [ ] Development app configuration (`env/development-firebase.local.json`, gitignored) and a dev Cloud Run service
- [ ] CI secrets per environment; never share keys between environments

**Owner actions:** choose the Firestore/Cloud Run region, install the `gcloud` CLI, provide the
release keystore through CI secrets, and link Play Console for Play Integrity. Confirm the
brand before creating more projects, since project IDs are permanent.

## Flutter wiring (implemented in Phase 2)
- `firebase_core` and `firebase_auth`. Options come from dart-defines (`env/*.json`) through
  `AppConfig.firebase`. No `google-services.json` or FlutterFire file is committed.
- `env/development.json` uses the Auth emulator with `demo-sprelia`.
- To use the development project once it exists: create a gitignored
  `env/development-firebase.local.json` with that project's values and **no** emulator host.
  The production project is refused in development builds.
- Production builds: `env/production.json` (gitignored, from `env/production.example.json`)
  with `FIREBASE_PROJECT_ID=sprelia` and the production app's identifiers, supplied by CI.

## Backend wiring (implemented)
- `FIREBASE_PROJECT_ID` selects the project whose ID tokens are accepted. It is checked
  against `APP_ENV` at startup.
- Credentials: Application Default Credentials (the Cloud Run service account for each
  environment). No key files. Never use production credentials locally.
- Local: `firebase emulators:start --only auth,firestore --project demo-sprelia` with
  `FIREBASE_AUTH_EMULATOR_HOST` and `FIRESTORE_EMULATOR_HOST`.

## Security rules roadmap
Phases 1–2 deny all client access, verified by `backend/test/integration/firestore.rules.test.ts`.
The owner-scoped rules described in `.agents/architecture.md` are written and tested on the
emulator first, and deployed to production only with explicit approval.
