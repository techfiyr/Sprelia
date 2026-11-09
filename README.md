# Sprelia

AI English-speaking coach (provisional brand; app ID `com.techfiyr.sprelia`, Dart package `speakdaily`).
Flutter (Android first, iOS-ready) + Node.js/TypeScript (Fastify) backend + Firebase + Gemini.

**Status:** Phases 1–2 complete. Phase 3 (Firebase integration and accounts: email/password
with verification, Google sign-in, session restore, account deletion, App Check support) is code
complete and verified locally, but blocked on owner-only Firebase, signing and policy items
(`doc/roadmap/phase_3.md`). Hosting is Netlify (API function + website, free plan). Live voice sessions are not
implemented yet; the legacy Emma prototype runs only in development builds.

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
Then create an account with any email and an 8+ character password. New email/password
accounts must verify their email: open the verification link printed by the Auth emulator
(terminal or Emulator UI at http://127.0.0.1:4000/auth), then tap "I've verified my email".

## Develop against the shared Firebase project (`sprelia`, test accounts only)
Needs Email/Password enabled in Firebase and `gcloud auth application-default login`. Uses the
gitignored `backend/.env.sprelia.local` and `env/development-firebase.local.json`
(see `doc/FIREBASE_SETUP.md`):
```bash
cd backend && npm run dev:sprelia
flutter run --dart-define-from-file=env/development-firebase.local.json
```

## Hosting (Netlify)
`netlify.toml` publishes the API as a Netlify Function (`/api/*`, free plan, default region) and the
website (landing page and **draft** policy pages) from `backend/netlify/public`. Firestore is in
`us-east5` (Ohio), next to the function. The Firebase key is set only as a Netlify secret by the
owner: `doc/DEPLOYMENT_NETLIFY.md`.

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
- `doc/DEPLOYMENT_NETLIFY.md`: hosting on Netlify (API function + website), credentials and owner steps
- `doc/reviews/LEGAL_PAGES_REVIEW.md`: review items for the website's draft policy pages
- `doc/`: approved product, flow, brand and design specifications
