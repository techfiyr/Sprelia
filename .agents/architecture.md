# Architecture

## System overview

```
Flutter app (Riverpod · GoRouter · Dio)
  │ HTTPS  Authorization: Bearer <Firebase ID token>   (+ X-Firebase-AppCheck, Phase 3)
  ▼
Sprelia API — Node.js/TypeScript, Fastify, Netlify Functions (default region)  backend/src/main.ts, backend/netlify/functions/api.mts
  │ Firebase Admin SDK: verifies ID tokens; writes trusted Firestore data
  │ Owns: identity, entitlements, usage/quota, AI session authorization, learning data
  ├──► Gemini Live API: app connects directly with a short-lived, constrained
  │    ephemeral token minted by the backend (Phase 6)
  ├──► Gemini (text): post-session analysis, server only (Phase 8)
  ▼
Cloud Firestore: default-deny rules. Phase 2: NO direct client access; all data via the API.
```

## Implemented decisions (Phase 1)

| Decision | Choice | Why |
|---|---|---|
| Brand | **Sprelia**, purple palette (`doc/BRAND.md`). Kept configurable in `lib/core/branding/app_brand.dart`. | Approved direction; the name is provisional. |
| App identity | Android `applicationId`/namespace and iOS bundle ID **`com.techfiyr.sprelia`**. Visible name "Sprelia". Dart package stays `speakdaily`. | Owner decision (2026-11-09): matches the Android app registered in Firebase project `sprelia`. Overrides `doc/roadmap/phase_2.md` §B ("keep existing IDs"). |
| Design tokens | Colors and weights from BRAND.md. Type scale, spacing names and components from DESIGN_SYSTEM.md. 4 px grid. | Resolves the conflict between the two documents. DESIGN_SYSTEM's teal palette is superseded. |
| Backend framework | **Fastify 5** (not Express) | APP_DEVELOPMENT §3 allows "NestJS or modular Fastify". Encapsulated plugins map to modules. Built-in pino structured logging. `inject()` testing without opening a port. Low overhead on serverless hosting (Netlify Functions). Less ceremony than NestJS for a small team. |
| Validation | Zod via the `validate()` preHandler (`backend/src/common/validate.ts`) | One schema library across the backend, with typed parsed output. |
| Logging | pino JSON with Cloud Logging fields (`severity`, `message`) and request IDs. Auth headers and tokens are redacted. Bodies are never logged. | Structured, safe by default. |
| API versioning | Path prefix `/api/v1` | Simple, cache-friendly, explicit. |
| Auth | Firebase ID token → `FirebaseTokenVerifier` (`verifyIdToken`, `checkRevoked`) behind a `TokenVerifier` interface | Testable without network; the Firebase SDK sits behind an interface. |
| Flutter config | `--dart-define-from-file=env/<env>.json`, validated by `AppConfig` (fails closed) | No secrets in the app. https is enforced outside development. |
| Flutter errors | `AppFailure` (user-safe messages), `ErrorReporter` (debug log now, Crashlytics in Phase 4), `AppProviderObserver`, global `FlutterError.onError` / `PlatformDispatcher.onError` | Nothing fails silently, and raw exceptions are never shown to users. |
| Navigation | GoRouter `StatefulShellRoute` with 5 tabs (Home, Practice, Learn, Progress, Profile). Tutor, prepare, conversation and feedback routes are pushed full-screen. | APP_FLOW §1. |

## Implemented decisions (Phase 2)

| Decision | Choice | Why |
|---|---|---|
| Accessibility tokens | Text secondary darkened to `#6A687C`. New `successText`, `warningText` and `errorText` (`#C82D2D`) for text and destructive fills. Base status hues kept for icons. Primary palette unchanged. | WCAG AA (BRAND §12). Enforced by tests. |
| Typeface | Inter v4.1 (OFL) static TTFs bundled (400/500/600/700) | BRAND §4; no runtime font downloads. |
| Client auth | Firebase Auth email/password behind `AuthRepository`. Errors are mapped so "wrong password" and "unknown account" look the same. Google sign-in comes once the provider is configured. No guest mode. | APP_FLOW §4; avoids account enumeration. |
| Firebase client config | Dart-side `FirebaseOptions` from dart-defines (`AppConfig.firebase`). Development uses the Auth emulator with `demo-sprelia`. The emulator and `demo-*` projects are refused outside development. No `google-services.json` in git. | Fails closed; no credentials in the repo. |
| Session and routing | `sessionProvider` (auth state → `GET /me/profile`, or `POST` to create it with the device IANA time zone) drives `sessionRedirect`: loading or error → splash (with retry); signed out → welcome/sign-in; not onboarded → onboarding; onboarded → app. | Single source of truth for access. The redirect is a pure, unit-tested function. |
| Onboarding persistence | The draft (step and answers) is saved to `SharedPreferences` per uid after every change. If there is no draft, onboarding resumes from server preferences. Answers are sent once, at the end, with `complete: true`. | Survives app kill (verified on device); no server writes per tap. |
| Onboarding completion | The server validates completeness on the **merged** stored preferences inside the Firestore transaction. Completed status is sticky. | Clients cannot mark onboarding complete with missing data. |
| Recommendations | Deterministic server-side rule (`recommendation.ts`): goals → categories; level and goals → tutor; first level-appropriate scenario. | Explainable; one implementation used by both onboarding and the dashboard. |
| Dashboard | Built only from server-recorded documents (`usage`, `dailyProgress`). Missing means zero. `plan` is always `free` until RevenueCat (Phase 9). | No invented progress (BRAND §7); never trusts the client. |
| Catalogue | Tutors and practice categories served from reviewed backend code (`modules/catalog`). Display fields only: no prompts, no voice names. | Read-only for clients. Moves to Firestore once an admin workflow exists. |
| Localization | `gen-l10n` with `lib/l10n/app_en.arb`. New Phase 2 screens use `context.l10n`. Interface language is applied from the saved preference when supported. | Phase 2 §E: architecture ready; only English shipped. |
| Provider retries | Riverpod automatic retry disabled (`retry: (_, _) => null`). Every error view has a manual retry. | No silent request loops; errors stay visible. |
| Voice in Phase 2 | Preparation enables "Start" only for tutors with `voiceAvailable` **and** only in development builds (legacy prototype). | Phase 2 excludes live sessions; the prototype must never ship. |

## Owner decisions applied at Phase 2 close-out (2026-11-09)

| Decision | Implementation |
|---|---|
| ~~Firebase `sprelia` = PRODUCTION; separate dev project~~ (superseded: single project, see below); emulators for tests | `PRODUCTION_FIREBASE_PROJECT_ID` guard in the backend `env.ts` and Flutter `AppConfig`; `doc/FIREBASE_SETUP.md` |
| Tutor–scenario compatibility enforced on the backend | `modules/catalog/compatibility.ts`: the tutor supports the category AND its range contains the scenario range. `CatalogService` refuses to start on violations and publishes `compatibleTutorIds`. The app offers only compatible tutors. |
| Study abroad: not Emma; Sofia only if she supports the category | Sofia doesn't support Academic, so **Alex** (A2–C1, Academic) |
| Networking: Alex only if his config supports Social | `social` explicitly added to Alex's `categoryIds` |
| Onboarding levels A1–C1 | `C1` added (backend enum, app enum, labels) |
| A1 Professional and Academic scenarios | `talking-about-work`, `classroom-basics` (Emma; Emma now supports Professional and Academic for beginner content) |
| More B2 Travel coverage | `trip-planning`, `changing-plans` (free), `local-culture` (premium): 4 B2 Travel scenarios |
| Every appropriate scenario recommendable | `recommendation.ts` rotates among all eligible scenarios (seed = uid + local date), with a closest-level fallback. Tested: every free scenario is reachable. |
| About five Premium scenarios | presentations, client-communication, academic-discussions, local-culture, social-events. Never recommended on the free plan; not startable in the app. |
| Durations 5, 10, 15 | Daily targets 5/10/15 (20 removed); scenario estimates in {5, 10, 15} (validated) |
| Human review before publishing | `reviewStatus` (`draft` / `approved` + reviewer and date). Production publishes approved scenarios only. All 27 are currently `draft`. |
| American English; flexible for British | Base content and ARB in en-US (tested). `content-variants.ts` overlays plus `?locale=en-GB` on the API; a future `app_en_GB.arb` for the app. |

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
    auth/                 AuthRepository (Firebase / unavailable), authStateProvider
    branding/             AppBrand (name, tagline), BrandLogo (PLACEHOLDER)
    config/               AppConfig (+ FirebaseClientConfig), AppEnvironment
    errors/               AppFailure, ErrorReporter, AppProviderObserver
    firebase/             initializeFirebase (options from dart-defines, emulator in dev)
    routing/              AppRoutes, routerProvider, sessionRedirect, AppShell
    services/             apiClientProvider (Dio + ID token interceptor), realtime/ (prototype)
    session/              sessionProvider (SignedOut / SignedIn(user, profile))
    storage/              sharedPreferencesProvider (non-sensitive data only)
    theme/                AppColors, AppPalette, AppTypography, AppSpacing, AppRadius, AppTheme
    widgets/              AppButton, AppCard, AppTextField, AppSelectionTile, AppLoading*, state views
  l10n/                   app_en.arb + generated AppLocalizations, context.l10n
  features/
    auth/                 SignInScreen (email sign-in / create account / reset)
    splash/               SplashScreen (loading, error + retry)
    onboarding/           Welcome, OnboardingScreen + steps/, controller, draft store, labels
    home/                 dashboard
    practice/             Practice tab, CategoryScreen, PrepareScreen, data/ (catalogue)
    tutors/               Tutor model, TutorsScreen, TutorAvatar (PLACEHOLDER)
    profile/              ProfileScreen, data/ (profile models + repository)
    learn/, progress/, feedback/   (empty states / prototype feedback)
backend/
  src/
    main.ts               entry: config → logger → Firebase Admin → app.listen
    app.ts                buildApp(deps): plugins, error handling, /api/v1 routes
    config/env.ts         Zod-validated environment (production guards)
    common/               errors, error-handler, validate, logger
    firebase/admin.ts     Admin SDK initialization (ADC, emulator in dev only)
    modules/
      auth/               TokenVerifier, FirebaseTokenVerifier, authenticate
      health/             GET /health
      users/              /me, /me/profile, /me/onboarding, /me/dashboard; repositories, schemas
      catalog/            /tutors, /practice/categories (reviewed content)
    server.ts …           LEGACY Express prototype (see below)
  test/                   Vitest unit tests (in-memory repository, fake verifier)
  test/integration/       Emulator Suite: real tokens + Firestore; firestore.rules tests
```

Flutter layering for new features (APP_DEVELOPMENT §5):
Presentation → Notifier/Controller → Repository → Service/API.

## Backend API (v1)

| Method | Path | Auth | Response |
|---|---|---|---|
| GET | `/api/v1/health` | none | `200 {"status":"ok"}`, nothing else, `cache-control: no-store` |
| GET | `/api/v1/me` | Bearer ID token | `200 {uid, email, emailVerified, signInProvider}` (read-only) |
| GET | `/api/v1/me/profile` | Bearer | `200 {profile}` or `404 PROFILE_NOT_FOUND` |
| POST | `/api/v1/me/profile` | Bearer | Body `{timezone, displayName?}` (strict). `201 {profile, created:true}`. If the profile exists: `200`, unchanged. uid and email come from the token. |
| PATCH | `/api/v1/me/profile` | Bearer (verified email) | Body `{displayName?: string|null, timezone?, preferredTutorId?: string|null, practiceReminders?}` (strict, ≥1 field). Time zone changes: once per 24 h (429 `TIMEZONE_CHANGE_TOO_SOON`). Unknown tutor → 400. |
| PATCH | `/api/v1/me/preferences` | Bearer (verified email) | Body `{preferences}` (partial, strict, ≥1 field). Same validated merge as onboarding; completion is kept. |
| GET | `/api/v1/me/export` | Bearer (verified email) | The caller's own data as JSON (`sprelia-export-v1`: profile, preferences, usage, daily progress); `content-disposition: attachment`. |
| POST | `/api/v1/me/conversations` | Bearer (verified email, onboarded) | Body `{tutorId, scenarioId?}` (strict; no client duration). Checks tutor/scenario fit and Premium, reserves min(remaining, 600 s) atomically (one active session; stale ones billed and closed), mints a Gemini Live ephemeral grant (v1beta, constrained, `uses: 1`). 201 `{conversationId, allowedDurationSeconds, expiresAt, realtime{provider, token, model, websocketUrl, openingInstruction}}`. Errors: `SESSION_ACTIVE` 409, `DAILY_LIMIT_REACHED` 403, `PREMIUM_REQUIRED` 403, `ONBOARDING_REQUIRED` 409, `VOICE_UNAVAILABLE` 503 (no `GEMINI_API_KEY` or provider failure; reservation released). |
| POST | `/api/v1/me/conversations/:id/end` | Bearer | Body `{reason, transcript?}` (`user_ended`, `time_limit`, `connection_lost`, `error`, `app_closed`; transcript ≤ 400 lines × 2000 chars, untrusted, stored only for feedback). Bills server-measured time capped at the reservation into `usage`, `dailyProgress` and the append-only `usageLedger`. Idempotent. |
| GET | `/api/v1/me/conversations/:id/feedback` | Bearer | `{status}`: `pending` (active/analysing; poll), `completed` `{feedback}`, `insufficient_speech` (< 15 learner words; no model call), `failed` `{message}` (retryable; no key, overload or timeout). Analysis once per session (create-once marker), Zod-validated, corrections kept only if quoted from the learner and confident; writes Mistake Vault and vocabulary in one batch. |
| GET/PATCH | `/api/v1/me/mistakes[/:id]`, `/api/v1/me/vocabulary[/:id]` | Bearer | Lists (newest first, `limit` ≤ 100); PATCH `{mastered}` / `{learned}` (owner only). |
| POST | `/api/v1/webhooks/revenuecat` | RevenueCat authorization value (constant-time) | Registered only with `REVENUECAT_WEBHOOK_AUTH` + `REVENUECAT_SECRET_API_KEY`. Outside the Firebase-token/App Check scope. Body never trusted: for each Firebase-UID app user ID (TRANSFER: both sides) the backend re-reads `GET /v1/subscribers/{id}` and stores `users/{uid}/subscription/current` (existing profiles only). 200 / 401 / 503 (RevenueCat retries). |
| GET | `/api/v1/me/subscription` | Bearer | Server-verified `{plan, expiresAt, store, dailyAllowanceSeconds}`. Premium scenarios, the Premium allowance (`PREMIUM_DAILY_SECONDS`, placeholder 1800 pending owner decision) and dashboard `plan` all use this entitlement. |
| GET | `/api/v1/me/progress` | Bearer | Last 30 local days, totals, streak, vault/vocabulary counts, recent sessions. |
| GET | `/api/v1/me/conversations[/:id]` | Bearer | The caller's sessions (newest first, `limit` ≤ 50) or one session. |
| PUT | `/api/v1/me/onboarding` | Bearer | Body `{preferences (partial, strict), complete?}`. Merges, then returns `{profile, plan}` (`plan` once completed). Completing with missing fields returns 400 listing them. |
| GET | `/api/v1/me/dashboard` | Bearer | `200 {dashboard}` from server data only (today, free allowance remaining, streak, weekly totals, recommendation) |
| GET | `/api/v1/tutors` | Bearer | Public tutor catalogue (no prompts or voices) |
| GET | `/api/v1/practice/categories?locale=en-US\|en-GB` | Bearer | Published categories with scenarios (CEFR range, objectives, vocabulary, minutes, premium, `compatibleTutorIds`). Default `en-US`. |

Ownership is structural: no route takes a uid; every read and write uses `request.user.uid`.

Error envelope (every non-2xx):

```json
{ "error": { "code": "INVALID_TOKEN", "message": "user-safe text", "details": [{"path":"body.x","message":"..."}], "requestId": "..." } }
```

Codes: `VALIDATION_ERROR` 400, `BAD_REQUEST` 400, `UNAUTHENTICATED` 401 (no or malformed
header), `INVALID_TOKEN` 401 (expired, revoked, forged, wrong project, disabled user),
`NOT_FOUND` 404, `PROFILE_NOT_FOUND` 404, `PAYLOAD_TOO_LARGE` 413, `UNSUPPORTED_MEDIA_TYPE` 415, `RATE_LIMITED` 429,
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

## Firebase layout

Implemented in Phase 2 (written only by the backend):
`users/{uid}` (profile: uid, email, displayName, timezone, onboardingStatus,
onboardingCompletedAt, createdAt, updatedAt, schemaVersion) and
`users/{uid}/preferences/learning`. Read but not yet written: `usage/{date}`
(`consumedSeconds`) and `dailyProgress/{date}` (`speakingSeconds`, `sessionsCompleted`).

Planned client access (Phase 4+; today every client read and write is denied):

```text
users/{uid}                                  owner read; limited validated owner writes
users/{uid}/preferences/{id}                 owner read/write (validated)
users/{uid}/conversations/{id}[/messages|/feedback]   owner read; backend write only
users/{uid}/mistakes/{id}, vocabulary/{id}   owner read; owner may update review fields only
users/{uid}/dailyProgress/{date}, usage/{date}, subscription/current   owner read; backend write only
tutors/{id}, scenarios/{id}                  signed-in read; backend write only
appConfig/{id}                               public fields read; backend write only
```

Firebase (**approved architecture decision, 2026-11-09**, supersedes the separate
`sprelia-dev` proposal): one project, **`sprelia`** (number 756773147926), is used for
development, integration testing where appropriate, and eventual production. Do not create
another Firebase project. Automated tests use the emulators (`demo-sprelia`). There is no public
release until the readiness checklist in `doc/roadmap/phase_3.md` §5 passes. Audit status:
Android app `com.techfiyr.sprelia` registered; no SHA fingerprints, no iOS app, no Firestore
database, Google provider not enabled. Code guards accept only `sprelia` or `demo-*` emulator
projects (`env.ts`, `AppConfig`).

## Provider abstraction
`RealtimeConversationProvider` (Flutter) and the planned `AIProvider` (backend) isolate
Gemini specifics. Add vendors as new implementations; never add vendor checks in UI.

## Hosting (owner decision 2026-11-09)
Netlify, not Cloud Run. One deploy publishes the API (Netlify Function `api` at `/api/*`, free plan,
default region, US East; Firestore is in `us-east5`, same area) and the static website (`backend/netlify/public`). `src/runtime.ts` wires the real
dependencies for both `main.ts` (long-running server) and the function, so routes and behavior are
identical. `src/serverless/netlify.ts` bridges Netlify's Request/Response to `app.inject()`.
Rate limits are in memory and therefore per function instance. See `doc/DEPLOYMENT_NETLIFY.md`.
