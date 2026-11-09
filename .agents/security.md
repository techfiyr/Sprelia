# Security requirements

Security is mandatory. These rules apply to every change. When a rule blocks a
task, stop and ask; do not work around it.

## 1. Secrets and credentials
- Permanent Gemini/API keys exist **only** in backend env vars, which come from
  Secret Manager in deployed environments. Never in Flutter, dart-defines, Firestore,
  logs, tests, fixtures, screenshots or git.
- Flutter `env/*.json` values are compiled into the binary and are public. They may hold
  only non-secret configuration such as `APP_ENV` and `API_BASE_URL`.
- The backend uses Application Default Credentials (the Cloud Run service account;
  locally, `gcloud auth application-default login`). Never create, download or commit
  service-account key files.
- `.gitignore` blocks `.env*` (except `.env.example`), keys, keystores, Firebase app
  configs and FlutterFire options. Never loosen it. `.env.example` holds placeholders only.
- Agents must never invent or fill in credentials. If one is needed, document the
  requirement and ask.

## 1a. Single Firebase project (approved architecture decision 2026-11-09)
Supersedes the earlier "separate development project" rule.
- One project, `sprelia`, serves development, integration testing where appropriate, and
  eventual production. Do not create another Firebase project.
- Automated tests always use the emulators (`demo-sprelia`) and must refuse any non-`demo-*`
  project. Manual or integration checks on `sprelia` use clearly identified test accounts and
  test data only. Never run destructive tests against real user data.
- No service-account key files anywhere. Local backend access uses personal Application Default
  Credentials. Production credentials and CI secrets stay out of git.
- Development-only mechanisms (emulator hosts, debug App Check providers, the prototype's
  `DEV_SKIP_AUTH`) must never reach a release build, and must never run against `sprelia` in a
  deployed environment.
- Before public release, complete the checklist in `doc/roadmap/phase_3.md` §5 (test data
  removed, rules verified, App Check enforced, app registrations verified, backend config
  verified, no auth bypasses, final security review).
- Code guards: the backend `loadConfig` and Flutter `AppConfig` accept only `sprelia` or `demo-*`
  (emulator) projects; staging/production must use `sprelia`; `APP_ENV=test` refuses any real
  project; the integration suite aborts unless it is on local emulators (`emulator-guard.ts`).
- Verify the project ID before every deployment. Never deploy rules or config to production
  without explicit approval.

## 2. Authentication and authorization (backend)
- Every protected route uses `authenticate(verifier)`. The caller's uid comes **only**
  from the verified token (`request.user`). Ignore uids in bodies, queries or headers.
- `FirebaseTokenVerifier` checks signature, expiry, audience/issuer (project) and,
  with `AUTH_CHECK_REVOKED=true`, revocation and disabled users.
- Missing or malformed header → 401 `UNAUTHENTICATED`. Rejected token → 401
  `INVALID_TOKEN`. Verification outage → 503. The client never learns why a token failed.
- `FIREBASE_AUTH_EMULATOR_HOST` makes the Admin SDK accept **unsigned** tokens.
  `loadConfig` refuses to start with it (or with revocation checks off) in staging/production.
- The legacy prototype's `DEV_SKIP_AUTH` header auth is local-only and defaults to
  `false`. Never deploy the prototype.
- App Check (Phase 3): `APP_CHECK_MODE` off/monitor/enforce on every route except health, before
  ID-token verification; production must be `enforce`. Tokens are never logged.
- Email/password accounts must verify their email (`EMAIL_NOT_VERIFIED`, 403) before using `/me/*`.
- Account deletion (`DELETE /me`) requires a sign-in within `RECENT_AUTH_MAX_AGE_SECONDS`
  (`REAUTH_REQUIRED`, 403), deletes `users/{uid}` recursively, then the Auth user. Own uid only.
  Immediate hard delete is a **recommendation (D2), not owner-approved**; the retention policy
  (APP_FLOW §17) is a release blocker.
  App Check never replaces authentication.

## 3. Server-authoritative data
- Never trust client-supplied subscription status, entitlement, usage, speaking
  duration, quota or timestamps. Usage is billed from server-measured time, and
  entitlements come from RevenueCat webhooks plus server-side verification.
- Clients cannot write usage, subscription, conversation, feedback, tutor, scenario or
  appConfig data. Those writes go through the backend.
- The Admin SDK bypasses Firestore rules, so every backend write must authorize the
  caller and validate the payload explicitly.

## 4. Firestore rules
- Default deny. Phase 2 `firestore.rules` still denies **all** client access; the app
  reaches data only through the authenticated API. `backend/test/integration/firestore.rules.test.ts`
  proves that owners cannot read or write their own documents directly, cannot grant
  themselves premium or usage, and cannot touch the catalogue or app config.
- Users access only `users/{their uid}/**`, and only the fields and operations listed in
  `architecture.md`. Validate field names, types and sizes on every permitted write. No
  broad wildcard writes.
- Every rule change ships with Emulator Suite tests (`@firebase/rules-unit-testing`).
  Never weaken a rule to fix an error.

### User-owned API data (Phase 2)
- No route accepts a uid. Profile, onboarding and dashboard always use `request.user.uid`.
- Profile creation is create-if-absent in a transaction and never overwrites. Email comes from
  the token, never from the body.
- Onboarding completion is validated on the merged, stored preferences inside the transaction.
- Dashboard values come only from server-written documents. Client query or header values are ignored.
- The catalogue exposes display fields only: no prompts, voice names or opening instructions.
- Catalogue integrity: the API refuses to start if a suggested tutor does not support the
  scenario's category or level range. Production serves only human-reviewed scenarios
  (`CATALOG_INCLUDE_DRAFTS` cannot be true in production).
- Premium scenarios are never recommended without a server-verified entitlement (none exist
  until Phase 9). Session creation (Phase 6) must re-check premium and tutor compatibility on the server.

## 5. Input validation and API hygiene
- Validate every request with Zod through `validate({ body, query, params })`. Use
  `.strict()` objects on writes so unknown fields like `plan` or `uid` are rejected.
- The body limit is 64 KB by default. Raise it per route only with a reason.
- Rate limiting is global per client IP. Add per-uid limits on costly routes (AI sessions).
- Errors use the central envelope. Never return stack traces, upstream messages,
  hostnames, versions or environment names. `/api/v1/health` returns only `{"status":"ok"}`.
- Security headers come from `@fastify/helmet`. Request IDs are accepted only when safe
  (`[A-Za-z0-9._-]{8,64}`).

## 6. Logging, analytics and crash reports
- Never log tokens, auth headers, cookies, App Check tokens, passwords, API keys,
  transcripts, audio or personal data. The pino redaction list is a safety net, not
  permission to log sensitive objects.
- Request and response bodies are not logged. Log codes, ids and counts.
- Analytics and Crashlytics never receive transcripts, audio, email or tokens.

## 7. Flutter client
- Firebase client identifiers are public, but real-project values still live only in
  gitignored env files and CI. `demo-*` projects and the emulator are refused outside development.
- Auth errors never reveal whether an account exists. Password reset always shows the same confirmation.
- `SharedPreferences` holds only non-sensitive data (the onboarding draft, per uid). Never
  store tokens, credentials, transcripts or personal data there. Firebase Auth manages its own session.
- Debug builds allow cleartext HTTP only to `10.0.2.2`, `localhost` and `127.0.0.1`
  (`android/app/src/debug/res/xml/network_security_config.xml`). This replaced the blanket
  `usesCleartextTraffic="true"`. Release builds keep the platform default (cleartext blocked).
- The legacy voice prototype can only be started from development builds.
- Show users only `AppFailure.message`, never `'$e'`, `toString()` of exceptions or raw
  server bodies. Report the original error through `ErrorReporter`.
- The client is untrusted. It may display limits (e.g. the free minutes) but never enforce
  or report them as authoritative.
- Release builds must use https (`AppConfig` enforces this) and never send the dev user header.
- Ask for microphone permission only when the user starts a conversation. Raw voice
  recordings are not stored by default.

## 8. Release safety
- Do not deploy, create or modify Firebase/GCP projects, change identifiers or signing,
  or run destructive commands without explicit approval.
- Release signing must use a real keystore supplied by CI secrets. Debug signing of
  release builds (current template default) must be replaced before any store upload.

## Security review checklist (run for every security-sensitive change)
- [ ] No secret or credential added anywhere; `git diff` checked for keys and tokens.
- [ ] Protected routes use `authenticate`; uid comes from `request.user` only.
- [ ] All inputs validated with strict Zod schemas; size limits set.
- [ ] Error responses leak nothing internal; logs contain no sensitive data.
- [ ] No client-trusted usage, entitlement or duration values.
- [ ] Firestore rules unchanged, or changed with emulator tests and approval.
- [ ] Tests cover the unauthenticated, invalid-token and invalid-input paths.
