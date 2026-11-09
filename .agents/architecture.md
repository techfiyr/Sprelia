# Architecture

```
Flutter app (mic capture, PCM playback, conversation UI)
   │  HTTPS: POST /v1/conversations  → short-lived token + live config
   ▼
Node.js backend (Cloud Run): Firebase Auth, quotas, session authorization, learner context
   │  creates a single-use, constrained ephemeral token
   ▼
Gemini Live API (native audio) ◄── app connects directly over WebSocket using the token
Gemini Flash (post-session analysis, structured JSON, runs on the backend)
   ▼
Firestore: transcripts · corrections · vocabulary · progress
```

## Realtime session lifecycle
1. App calls `POST /v1/conversations` with tutorId and optional scenarioId.
2. Backend authenticates the user, checks the entitlement, and reserves usage atomically.
3. Backend builds the tutor's system prompt and voice config, then mints a Gemini
   ephemeral token. The token is locked to that model and config, valid for one use,
   and short-lived.
4. App connects to the Live API with the token, streams 16 kHz PCM16 mono mic audio,
   and plays 24 kHz PCM16 output.
5. Input and output transcription events build the live transcript.
6. App calls `POST /v1/conversations/:id/end`. The backend finalizes usage
   idempotently and queues analysis.

The model's system prompt and voice are fixed server-side through the token
constraints, so a modified client cannot swap in a different persona or model.

## Provider abstraction
`lib/core/services/realtime/realtime_provider.dart` defines `RealtimeConversationProvider`.
`GeminiLiveProvider` is the only vendor implementation today. Add other vendors as
new implementations. Do not add vendor checks inside the UI.

## Security
- Gemini API key: backend env var or Secret Manager only.
- Prototype backend has a `DEV_SKIP_AUTH` flag. It must be false in any deployed environment.
- Firestore rules: users read and write only their own docs. Usage and subscription
  docs are backend-write-only.
