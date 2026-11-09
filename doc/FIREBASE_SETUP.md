# Firebase setup (required configuration)

Status (2026-11-09):
- Firebase project **`sprelia`** exists. Project ID `sprelia`, project number `756773147926`.
  The number is not the ID; tools and `FIREBASE_PROJECT_ID` take the **ID**.
- Android app registered: `com.techfiyr.sprelia`
  (`1:756773147926:android:1bc8ce332ae6b5ccce2c37`). No SHA-1/SHA-256 fingerprints yet.
- iOS app: not registered. Auth providers, Firestore database, App Check: not verified or not set up.
- It is the only project, and whether it is dev or prod is undecided. Agents must not change
  its configuration or deploy to it without explicit owner approval. Local development
  uses the emulators with `demo-sprelia`.

The repo contains local scaffolding only: `firebase.json` (emulators), `firestore.rules`
and `firestore.indexes.json`.

## 1. Projects (owner action)
Create one Firebase project per environment, all in the same region as Cloud Run:

| Environment | Suggested project ID | Purpose |
|---|---|---|
| (existing) | `sprelia` | role to be decided by the owner (dev or prod) |
| development | `sprelia-dev` (suggested) | if `sprelia` becomes production |
| staging | `sprelia-staging` (suggested) | internal testing builds |

Project IDs are permanent. Confirm the brand name before creating them.
Also enable billing for Cloud Run and Secret Manager, and confirm the Gemini API
paid tier for learner data.

## 2. Per project
1. **Authentication**: enable the Google and Email/Password providers. Turn on email
   enumeration protection.
2. **Apps**: Android `com.techfiyr.sprelia` (registered in `sprelia`) and iOS
   `com.techfiyr.sprelia` (not registered yet). Add debug and release SHA-1/SHA-256 fingerprints for
   Google Sign-In and Play Integrity.
3. **Firestore**: create the database in Native mode, choose a location, then deploy the
   rules from this repo (after emulator tests and approval).
4. **App Check**: Play Integrity (Android) and App Attest (iOS); debug provider for
   development. Start in *monitor* mode and enforce after metrics look healthy.
5. **Cloud Run service account**: grant it only the roles it needs (Firebase Auth admin
   for token revocation checks, Datastore user for Firestore). Use no key files.

## 3. Flutter wiring
Done in Phase 2:
- `firebase_core` and `firebase_auth`. Options come from dart-defines (`env/*.json`) through
  `AppConfig.firebase`. No `google-services.json` or FlutterFire file is needed or committed.
- Development: Auth emulator with `demo-sprelia` (`env/development.json`).
- Dio interceptor: `Authorization: Bearer <ID token>`, with one forced refresh and retry on 401.

To run the app against the real `sprelia` project (owner decision; do not commit the file):
1. In Firebase console → Authentication, enable **Email/Password**.
2. Create `env/sprelia.local.json` (gitignored by `env/*.local.json`) with `APP_ENV`
   `development`, your API URL, `FIREBASE_PROJECT_ID=sprelia`, and `FIREBASE_API_KEY`,
   `FIREBASE_APP_ID` (`1:756773147926:android:1bc8ce332ae6b5ccce2c37`) and
   `FIREBASE_MESSAGING_SENDER_ID` (`756773147926`) from the Android app's config. Leave out
   `FIREBASE_AUTH_EMULATOR_HOST`.
3. Run the backend with `FIREBASE_PROJECT_ID=sprelia` and Application Default Credentials
   (`gcloud auth application-default login`), no emulator variables.

Phase 4: App Check, Google sign-in (needs SHA fingerprints), Crashlytics and Analytics.

## 4. Backend wiring (done in Phase 1)
- `FIREBASE_PROJECT_ID` selects the project whose ID tokens are accepted.
- Credentials: Application Default Credentials (Cloud Run service account; locally
  `gcloud auth application-default login`).
- Local without a project: `firebase emulators:start --project demo-sprelia` and
  `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099` (development only; staging and
  production refuse to start with it).

## 5. Security rules roadmap
Phases 1–2 deny all client access, verified by `backend/test/integration/firestore.rules.test.ts`. Phase 4 adds the owner-scoped rules described in
`.agents/architecture.md` together with `@firebase/rules-unit-testing` tests run on
the emulator. A rule change without tests is not mergeable.

## Owner checklist
- [ ] Confirm brand / project naming
- [x] Project `sprelia` created, Android app registered
- [ ] Decide whether `sprelia` is dev or prod; create the remaining environments
- [ ] Register the iOS app; add SHA fingerprints to the Android app
- [ ] Choose a region (Firestore + Cloud Run)
- [ ] Install the `gcloud` CLI locally
- [ ] Provide release signing keystore (via CI secrets, never in git)
- [ ] Link Play Console for Play Integrity
