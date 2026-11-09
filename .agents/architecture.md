# Architecture

## System overview

```
Flutter app (Riverpod · GoRouter · Dio)
  │ HTTPS  Authorization: Bearer <Firebase ID token>   (+ App Check token, Phase 4)
  ▼
Sprelia API — Node.js/TypeScript, Fastify, Cloud Run          backend/src/main.ts
  │ Firebase Admin SDK: verifies ID tokens; writes trusted Firestore data
  │ Owns: identity, entitlements, usage/quota, AI session authorization, learning data
  ├──► Gemini Live API: app connects directly with a short-lived, constrained
  │    ephemeral token minted by the backend (Phase 6)
  ├──► Gemini (text): post-session analysis, server only (Phase 8)
  ▼
Cloud Firestore: default-deny rules; clients read their own data only (Phase 4)
```

## Implemented decisions (Phase 1)

| Decision | Choice | Why |
|---|---|---|
| Brand | **Sprelia**, purple palette (`doc/BRAND.md`). Kept configurable in `lib/core/branding/app_brand.dart`. | Approved direction; the name is provisional. |
| App identity | Android `applicationId`/namespace and iOS bundle ID **`com.techfiyr.sprelia`**. Visible name "Sprelia". Dart package stays `speakdaily`. | Owner decision (2026-11-09): matches the Android app registered in Firebase project `sprelia`. Overrides `doc/roadmap/phase_2.md` §B ("keep existing IDs"). |
| Design tokens | Colors and weights from BRAND.md. Type scale, spacing names and components from DESIGN_SYSTEM.md. 4 px grid. | Resolves the conflict between the two documents. DESIGN_SYSTEM's teal palette is superseded. |
| Backend framework | **Fastify 5** (not Express) | APP_DEVELOPMENT §3 allows "NestJS or modular Fastify". Encapsulated plugins map to modules. Built-in pino structured logging. `inject()` testing without opening a port. Lower overhead on Cloud Run. Less ceremony than NestJS for a small team. |
| Validation | Zod via the `validate()` preHandler (`backend/src/common/validate.ts`) | One schema library across the backend, with typed parsed output. |
| Logging | pino JSON with Cloud Logging fields (`severity`, `message`) and request IDs. Auth headers and tokens are redacted. Bodies are never logged. | Structured, safe by default. |
| API versioning | Path prefix `/api/v1` | Simple, cache-friendly, explicit. |
| Auth | Firebase ID token → `FirebaseTokenVerifier` (`verifyIdToken`, `checkRevoked`) behind a `TokenVerifier` interface | Testable without network; the Firebase SDK sits behind an interface. |
| Flutter config | `--dart-define-from-file=env/<env>.json`, validated by `AppConfig` (fails closed) | No secrets in the app. https is enforced outside development. |
| Flutter errors | `AppFailure` (user-safe messages), `ErrorReporter` (debug log now, Crashlytics in Phase 4), `AppProviderObserver`, global `FlutterError.onError` / `PlatformDispatcher.onError` | Nothing fails silently, and raw exceptions are never shown to users. |
| Navigation | GoRouter `StatefulShellRoute` with 5 tabs (Home, Practice, Learn, Progress, Profile). Tutor, prepare, conversation and feedback routes are pushed full-screen. | APP_FLOW §1. |

## Repository layout

```text
CLAUDE.md                 agent entry point
.agents/                  agent rules (protected)
doc/                      approved specs (protected)
env/                      Flutter --dart-define-from-file inputs (no secrets)
firebase.json             emulator config; Firestore rules/indexes paths
firestore.rules           DEFAULT DENY (Phase 1)
lib/
  main.dart               bootstrap: config validation, global error handlers, ProviderScope
  app.dart                SpreliaApp (MaterialApp.router), ConfigErrorApp
  core/
    branding/             AppBrand (name, tagline), BrandLogo (PLACEHOLDER)
    config/               AppConfig, AppEnvironment, appConfigProvider
    errors/               AppFailure, ErrorReporter, AppProviderObserver
    routing/              AppRoutes, routerProvider, AppShell (bottom nav)
    services/             apiClientProvider (Dio), realtime/ (Gemini Live prototype)
    theme/                AppColors, AppPalette, AppTypography, AppSpacing, AppRadius, AppTheme
    widgets/              AppButton, AppCard, AppTextField, AppLoading*, AppEmptyState, AppErrorState
  features/<feature>/     screens, widgets, controllers per feature
backend/
  src/
    main.ts               entry: config → logger → Firebase Admin → app.listen
    app.ts                buildApp(deps): plugins, error handling, /api/v1 routes
    config/env.ts         Zod-validated environment (production guards)
    common/               errors, error-handler, validate, logger
    firebase/admin.ts     Admin SDK initialization (ADC, emulator in dev only)
    modules/<module>/     auth, health, users, … (one Fastify plugin per module)
    server.ts …           LEGACY Express prototype (see below)
  test/                   Vitest
```

Flutter layering for new features (APP_DEVELOPMENT §5):
Presentation → Notifier/Controller → Repository → Service/API.

## Backend API (v1)

| Method | Path | Auth | Response |
|---|---|---|---|
| GET | `/api/v1/health` | none | `200 {"status":"ok"}`, nothing else, `cache-control: no-store` |
| GET | `/api/v1/me` | Bearer ID token | `200 {uid, email, emailVerified, signInProvider}` (read-only) |

Error envelope (every non-2xx):

```json
{ "error": { "code": "INVALID_TOKEN", "message": "user-safe text", "details": [{"path":"body.x","message":"..."}], "requestId": "..." } }
```

Codes: `VALIDATION_ERROR` 400, `BAD_REQUEST` 400, `UNAUTHENTICATED` 401 (no or malformed
header), `INVALID_TOKEN` 401 (expired, revoked, forged, wrong project, disabled user),
`NOT_FOUND` 404, `PAYLOAD_TOO_LARGE` 413, `UNSUPPORTED_MEDIA_TYPE` 415, `RATE_LIMITED` 429,
`SERVICE_UNAVAILABLE` 503 (token verification could not complete), `INTERNAL` 500.

## Legacy prototype (still present, to be migrated)

The Emma voice prototype still runs on Express (`backend/src/server.ts`, `tokens.ts`,
`usage.ts`, `analysis.ts`, `tutors.ts`, `config.ts`) via `npm run dev:prototype`.
It serves unversioned `/v1/*` routes, uses `DEV_SKIP_AUTH` header auth and an in-memory
store. The Flutter conversation flow still calls it. Phase 6 moves conversations
into the Fastify API (`/api/v1/conversations`) with Firebase Auth and Firestore, then
deletes the prototype and Express. Until then, never deploy the prototype.

### Realtime session lifecycle (target design, Phase 6–7)
1. App: `POST /api/v1/conversations {tutorId, scenarioId?}`.
2. Backend verifies the ID token (and App Check), loads the server-side entitlement,
   and reserves usage atomically in a Firestore transaction.
3. Backend mints a single-use Gemini ephemeral token, locked to the model, system
   prompt and voice and expiring with the allowed duration.
4. App connects to the Live API WebSocket with the token: 16 kHz PCM16 mono in,
   24 kHz PCM16 out. It handles `GoAway` with session resumption, because a connection lasts about 10 min.
5. App: `POST /api/v1/conversations/:id/end` (idempotent). The backend bills
   server-measured time, then queues analysis.

### Gemini facts verified 2026-11-09 (re-verify before Phase 6)
- Ephemeral tokens: preview, Live API only, **v1beta**. The prototype uses v1alpha and must be fixed.
  Passed as the `access_token` query parameter or `Authorization: Token <t>`. Defaults are a
  1 min start window and 30 min expiry.
- Live models: `gemini-3.8-live` (GA, default). The prototype's
  `gemini-2.5-flash-native-audio-preview-09-2025` is superseded.
- Text: `gemini-2.5-flash` is deprecated (it reroutes to `gemini-3.5-flash-lite` from 2026-12-01).
  Candidates: `gemini-3.8-flash`, `gemini-3.5-flash-lite`.
- Model IDs stay in backend env vars, never in Flutter.

## Firebase layout (planned schema, enforced from Phase 4)

```text
users/{uid}                                  owner read; limited validated owner writes
users/{uid}/preferences/{id}                 owner read/write (validated)
users/{uid}/conversations/{id}[/messages|/feedback]   owner read; backend write only
users/{uid}/mistakes/{id}, vocabulary/{id}   owner read; owner may update review fields only
users/{uid}/dailyProgress/{date}, usage/{date}, subscription/current   owner read; backend write only
tutors/{id}, scenarios/{id}                  signed-in read; backend write only
appConfig/{id}                               public fields read; backend write only
```

Firebase: project **`sprelia`** (number 756773147926) exists with an Android app
`com.techfiyr.sprelia` (no SHA fingerprints, no iOS app yet). Staging/production
projects are not created. Local development uses the emulators (`demo-sprelia`).
See `doc/FIREBASE_SETUP.md`.

## Provider abstraction
`RealtimeConversationProvider` (Flutter) and the planned `AIProvider` (backend) isolate
Gemini specifics. Add vendors as new implementations; never add vendor checks in UI.
