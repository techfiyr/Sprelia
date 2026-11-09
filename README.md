# Sprelia

AI English-speaking coach (provisional brand; the code package is still `speakdaily`).
Flutter (Android first, iOS-ready) + Node.js/TypeScript (Fastify) backend + Firebase + Gemini.

**Status: Phase 1 (foundation) complete.** It includes the design system, routing,
environment config, error handling, and a Fastify API with Firebase ID token
verification. The Emma voice prototype still runs on the legacy Express server.

## Quick start

```bash
# Backend API
cd backend
npm install
cp .env.example .env          # placeholders only; never commit .env
npm run dev                   # http://localhost:8080/api/v1/health → {"status":"ok"}
npm test && npm run typecheck

# Flutter app (repo root)
flutter pub get
flutter run --dart-define-from-file=env/development.json
flutter analyze && flutter test
```

### Legacy voice prototype (Emma on Gemini Live)
```bash
cd backend
# in .env: GEMINI_API_KEY=<your key>, DEV_SKIP_AUTH=true (local machine only)
npm run dev:prototype         # serves /v1/conversations on :8080
```
Then run the app as above and tap **Start Speaking**. The prototype uses
superseded Gemini model IDs and a v1alpha token endpoint; Phase 6 replaces it.

## Documentation
- `CLAUDE.md`: rules for AI agents (start here)
- `.agents/architecture.md`: architecture and implemented decisions
- `.agents/security.md`: security requirements and review checklist
- `.agents/development.md`: commands, conventions, testing, phase status
- `doc/FIREBASE_SETUP.md`: required Firebase configuration
- `doc/`: approved product, flow, brand and design specifications
