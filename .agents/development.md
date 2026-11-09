# Development guide

## Toolchain (verified 2026-11-09)
Flutter 3.47.2 stable / Dart 3.13.2 · Node 26 (backend requires >= 22) · npm 11 ·
Firebase CLI 15.34 · Java 21 (Flutter/Gradle; also needed by the Firestore emulator).
Not installed yet: `gcloud` CLI. Some Android SDK licenses are not accepted yet
(`flutter doctor --android-licenses`).

## Commands

### Full local stack (no real Firebase project needed)
```bash
# 1) Firebase emulators (repo root): Auth :9099, Firestore :8180, UI http://127.0.0.1:4000
firebase emulators:start --only auth,firestore --project demo-sprelia
# 2) API against the emulators (backend/.env from .env.example, then uncomment the two
#    emulator lines), or inline:
cd backend && APP_ENV=development FIREBASE_PROJECT_ID=demo-sprelia \
  FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIRESTORE_EMULATOR_HOST=127.0.0.1:8180 npm run dev
# 3) App on the Android emulator (uses 10.0.2.2 for the API and the Auth emulator)
flutter run --dart-define-from-file=env/development.json
```
Create an account in the app with any email and an 8+ character password. Accounts live
only in the Auth emulator.

### Flutter app (repo root)
```bash
flutter pub get
flutter gen-l10n                                                # after editing lib/l10n/*.arb (also runs on build)
flutter analyze
flutter test
flutter run --dart-define-from-file=env/development.json        # Android emulator → host 10.0.2.2:8080
flutter run --dart-define-from-file=env/development.json \
  --dart-define=API_BASE_URL=http://192.168.x.y:8080            # physical device on your LAN
flutter build apk --debug --dart-define-from-file=env/development.json
```

### Backend (`backend/`)
```bash
npm install
cp .env.example .env            # placeholders only; never commit .env
npm run dev                     # Sprelia API (Fastify) → http://localhost:8080/api/v1/health
npm run typecheck               # tsc over src + test
npm test                        # Vitest unit tests
npm run test:integration        # Auth + Firestore emulators: real tokens, Firestore, security rules (needs Java)
npm run build && npm start      # compiled dist/main.js
npm run dev:prototype           # LEGACY Express voice prototype (needs GEMINI_API_KEY, DEV_SKIP_AUTH=true locally)
```
`npm run dev` and `npm run dev:prototype` both default to port 8080. Run one at a time,
or set `PORT`.

### Firebase emulators (repo root, no real project needed)
```bash
firebase emulators:start --project demo-sprelia    # Auth :9099, Firestore :8180, UI :4000
# backend/.env: FIREBASE_PROJECT_ID=demo-sprelia, FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
```

## Conventions

### General
- Feature-first layout. Shared code goes in `lib/core/` (Flutter) or `backend/src/common/` (backend).
- Small, reviewable changes. Never regenerate the Flutter project or remove working code.
- No hardcoded user-facing product name: use `AppBrand.name`.
- Comments explain *why*. Mark placeholders explicitly (`PLACEHOLDER`), and give TODOs an
  owner tag (`TODO(auth): …`).

### Flutter (see also `flutter.md`)
- Riverpod (`Notifier`/`AsyncNotifier`, `Provider`). No global mutable singletons.
- Layering: Presentation → Notifier → Repository → Service/API. No business logic in widgets.
- Styling only through the theme: `context.colors`, `context.palette`, `context.textStyles`,
  `AppSpacing`/`Gap`, `AppRadius`. **No `Color(0x…)`, `Colors.*` or raw font sizes in `lib/features/`.**
- Components: use `lib/core/widgets/widgets.dart` (`AppButton`, `AppCard`, `AppTextField`,
  `AppLoadingView`, `AppEmptyState`, `AppErrorState`, `BrandLogo`) instead of ad-hoc widgets.
- Navigation: `AppRoutes` constants and helpers, never string literals.
- Errors: `AppFailure.from(e)` for display, `ErrorReporter` for diagnostics.
- Every screen handles loading, empty, error (with retry) and offline states.
- Lints: `flutter_lints` plus the project rules in `analysis_options.yaml`.

### Backend
- One Fastify plugin per module in `src/modules/<module>/` (`*.routes.ts`, services,
  schemas). Register it in `app.ts` under `API_PREFIX`.
- Inject external services (Firebase, Gemini, RevenueCat) through interfaces so tests run offline.
- Validate with `validate({ body, query, params })`. Throw `AppError` and never call
  `reply.code(4xx).send(...)` ad hoc.
- Config only through `loadConfig()`. Add new env vars to the Zod schema and to
  `.env.example` (placeholder values).
- ESM + NodeNext: relative imports end in `.js`. `strict` + `noUncheckedIndexedAccess`.

## Testing rules
- Flutter: unit tests for config, errors and models. Widget tests for components and
  routing (`test/helpers/pump_app.dart`).
- Backend: `app.inject()` tests per route, covering the **unauthenticated, invalid-token,
  invalid-input, ownership and success** paths for every protected endpoint. Plus tests showing
  that error responses and logs leak nothing.
- Backend integration (`test/integration`, run in `firebase emulators:exec`): real Auth emulator
  tokens, real Admin SDK verification (including revocation), real Firestore repositories.
- Firestore rules: Emulator Suite tests for every allow and deny path (`firestore.rules.test.ts`).
- Flutter app-level tests use `test/helpers/pump_app.dart` + `fakes.dart` (fake auth, profile and
  catalogue repositories). Simulate an app restart by pumping again with the same `TestBackend`
  and `SharedPreferences`.
- Tests never call real Firebase, Google or Gemini services or use real credentials.
- A bug fix comes with a test that fails without the fix.

## Definition of done (every change, every milestone)
1. `flutter analyze`: no issues.
2. `flutter test`: all pass.
3. `cd backend && npm run typecheck && npm test`: all pass.
4. `flutter build apk --debug --dart-define-from-file=env/development.json` succeeds
   for changes touching native config or dependencies.
5. Security checklist (`security.md`) reviewed for security-sensitive changes.
6. Docs in `.agents/` updated when a decision or convention changes.

## Git
- `main` is the default branch. Work on feature branches, and commit only when the owner asks.
- Commit messages: imperative summary plus a body explaining why.
- Before committing, check `git status` and `git diff --cached` for secrets.

## Phase status

| Phase | Status |
|---|---|
| 1. Foundation (architecture, design system, routing, env config, error handling, Fastify API with auth middleware, Firebase scaffolding, guardrails) | **Done** (branch `phase-1-foundation`) |
| 2. Experience: docs completed, contrast fixes, Inter, l10n, email auth, onboarding with persistence, home dashboard, tutors, practice categories, preparation; profile, onboarding, dashboard and catalogue APIs | **Done**, awaiting approval (branch `phase-2-experience`) |
| 3. Backend foundation: remaining modules, `AIProvider`, Dockerfile | Not started |
| 4. Firebase projects, Auth, App Check, Firestore rules + emulator tests, Crashlytics/Analytics | Not started (needs approval to create projects) |
| 5–10. Onboarding/profile, Gemini realtime, quotas, feedback, monetization, release | Not started |
