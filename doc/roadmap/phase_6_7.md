# Phases 6–7: Live voice sessions and daily quotas

**Status:** `[x]` Implemented and verified locally (2026-11-09). Built together because a session
cannot start without a server-side reservation.

## Verified provider facts (official docs, 2026-11-09; the docs moved to aistudio.google.com)
- Ephemeral tokens: `v1beta` only; `uses`, `expireTime` (default 30 min, < 20 h), `newSessionExpireTime`
  (default 60 s), `liveConnectConstraints`; SDK `lockAdditionalFields: []` locks all set fields.
- WebSocket: `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained?access_token=<token>`.
- Model: `gemini-3.8-live` (default; `gemini-3.1-flash-live-preview` is legacy).
- Audio: PCM16 LE 16 kHz in, 24 kHz out. Connection ≈ 10 min; audio-only session 15 min.
- `@google/genai` 3.0.0 comment says "v1alpha only", but the SDK uses the client's configured
  version; the provider sets `v1beta` as the docs require.

## Backend
| Part | Implementation |
|---|---|
| AI boundary | `AIProvider` (`modules/conversations/ai-provider.ts`); `GeminiProvider`; `createAIProvider(config)`: no `GEMINI_API_KEY` → `UnavailableAIProvider` → 503 `VOICE_UNAVAILABLE` (startup log says why). Key is non-enumerable in config and redacted from logs |
| Personas | Emma (Aoede), Alex (Charon), Sofia (Kore); shared rules: short turns, no mid-conversation grammar correction, prompt-injection resistant; scenario objectives and vocabulary; learner level and accent |
| Reservation | `POST /me/conversations`: one active session per user; stale (expired) sessions billed at their reservation and closed in the same transaction; reserves min(remaining, `MAX_SESSION_SECONDS`=600); refuses below `MIN_SESSION_SECONDS`=30; provider failure → session `failed`, nothing billed |
| Billing | `POST …/end`: server-measured, capped at the reservation, idempotent; writes `usage/{date}`, `dailyProgress/{date}`, `usageLedger/{auto}` (append-only); clients never report durations |
| Day boundary | Local calendar day of the profile time zone (time zone changes limited to 1/day, Phase 5) |

## App
- `ApiConversationRepository` (`/api/v1/me/conversations`): maps server codes to typed start
  failures; recovers a left-over active session once (ends it, retries).
- `ConversationController`: injectable realtime vendor, microphone and speaker (tests use fakes);
  mic permission checked before reserving; server end reasons; dashboard refreshed after a session.
- Scenario passed through the route (`/conversation/:tutorId?scenario=`). Preparation "Start" now
  requires a suited voice tutor, no Premium lock and ≥ 30 s of free time (the prototype-only gate
  was removed; all three tutors have voices).

## Verification
| Check | Result |
|---|---|
| Backend unit | All pass (new `test/conversations.test.ts`, 18 tests: reservation, limits, Premium, provider failure, billing caps, idempotency, reconciliation, isolation, token never logged, missing key) |
| Emulator integration | All pass (new: reserve/bill/ledger, abandoned-session reconciliation that commits when the limit is reached, isolation) |
| Live Gemini (`npm run test:live`, opt-in, key from the gitignored root `.env`) | Passed: constrained v1beta token minted and a `gemini-3.8-live` session setup completed (no audio sent) |
| Flutter | All pass (new `test/features/conversation_test.dart`, 10 tests; updated preparation gating tests) |

## Not covered / later
- Real audio on a device (microphone, echo cancellation, playback) needs a manual device test.
- Session resumption (sessions are capped below the ~10 min connection lifetime instead).
- Premium allowance (Phase 9) and post-session analysis (Phase 8).
