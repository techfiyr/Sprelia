# SpeakDaily

AI English speaking coach. Flutter (Android first, iOS-ready) + Node.js/TypeScript backend.

**Current phase: Emma prototype on Gemini Live.** The goal is to validate latency, voice quality,
interruptions, transcript accuracy and correction quality before building the full learning system.

## Run the prototype

1. Backend
   ```bash
   cd backend
   cp .env.example .env        # add GEMINI_API_KEY; confirm model IDs are current
   npm install
   npm run dev                 # http://localhost:8080
   ```
2. App (Android emulator reaches the host at 10.0.2.2)
   ```bash
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```
   On a physical device, use your machine's LAN IP, e.g. `--dart-define=API_BASE_URL=http://192.168.1.20:8080`.

## How a session works
App → `POST /v1/conversations` → backend reserves the daily quota and mints a single-use
Gemini ephemeral token with Emma's prompt, voice and model locked in → app opens the Live
WebSocket directly (16 kHz mic in, 24 kHz audio out) → `POST /v1/conversations/:id/end` →
Gemini Flash analyses the transcript → `GET /v1/conversations/:id/feedback`.

See `.agents/architecture.md` for details and `.agents/AGENTS.md` for repo rules.

## Prototype shortcuts (must change before launch)
- `DEV_SKIP_AUTH` header auth, so Firebase Auth isn't wired up yet.
- In-memory conversations and usage ledger, which are lost on restart. These move to Firestore transactions.
- The client uploads the transcript at session end.
- Learner level is hardcoded to A2. Onboarding screens 3–10 are not built yet.
- No session resumption after a network drop.
