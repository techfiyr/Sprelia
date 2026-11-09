# Sprelia

AI English-speaking coach (provisional brand; app ID `com.techfiyr.sprelia`, Dart package `speakdaily`).
Flutter (Android first, iOS-ready) + Node.js/TypeScript (Fastify) backend + Firebase + Gemini.

**Status: Phase 2 (application experience) complete.** It includes email sign-in,
onboarding that survives app restarts, the home dashboard, tutor selection, practice
categories and preparation, backed by authenticated profile, onboarding, dashboard and
catalogue APIs. Live voice sessions are not part of Phase 2. The legacy Emma prototype
runs only in development builds.

## Run everything locally (no real Firebase project needed)

```bash
# 1. Firebase emulators (repo root; needs Java): Auth :9099, Firestore :8180, UI :4000
firebase emulators:start --only auth,firestore --project demo-sprelia

# 2. API (new terminal)
cd backend && npm install && cp -n .env.example .env   # placeholders only
APP_ENV=development FIREBASE_PROJECT_ID=demo-sprelia \
  FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIRESTORE_EMULATOR_HOST=127.0.0.1:8180 npm run dev
#    → http://localhost:8080/api/v1/health

# 3. App on an Android emulator (new terminal, repo root)
flutter pub get
flutter run --dart-define-from-file=env/development.json
```
Then create an account with any email and an 8+ character password.

## Checks
```bash
flutter analyze && flutter test
cd backend && npm run typecheck && npm test && npm run build
cd backend && npm run test:integration   # emulator-backed API + Firestore rules tests
```

## Documentation
- `CLAUDE.md`: rules for AI agents (start here)
- `.agents/architecture.md`: architecture, implemented decisions, API reference
- `.agents/security.md`: security requirements and review checklist
- `.agents/development.md`: commands, conventions, testing, phase status
- `doc/FIREBASE_SETUP.md`: Firebase status and configuration
- `doc/`: approved product, flow, brand and design specifications
