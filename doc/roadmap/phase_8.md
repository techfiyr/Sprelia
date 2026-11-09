# Phase 8: Feedback, Mistake Vault, vocabulary and progress

**Status:** `[x]` Implemented and verified locally (2026-11-09). Open owner decision: transcript
retention period (APP_DEVELOPMENT §14/§19); transcripts are stored per session until then and are
deleted with the account.

## Flow
1. The app uploads the live transcription with `POST /me/conversations/:id/end` (`transcript`,
   untrusted, size-limited). Stored at `users/{uid}/conversations/{id}/private/transcript`.
2. The feedback screen polls `GET /me/conversations/:id/feedback`. The first request claims the
   analysis with a create-once marker, calls the analysis model once, validates the JSON with Zod,
   drops corrections that are low-confidence, unchanged, or not quoted from the learner
   (anti-fabrication), then writes feedback, Mistake Vault entries and vocabulary in one batch.
3. `insufficient_speech` below 15 learner words (no model call). `failed` is retryable (no key,
   provider overload, timeout); the marker is released.

## Reliability (found by the live check)
The primary model `gemini-3.8-flash` returned "503 high demand" and hung during testing. The
analyzer now uses a 25 s per-attempt timeout and falls back once to `gemini-3.5-flash-lite`, so a
request stays inside Netlify's 60 s limit and fails as a retryable status instead of hanging.

## App
- `LearningRepository` (feedback, mistakes, vocabulary, progress) with polling (`feedbackProvider`).
- Learn tab: Mistake Vault and Vocabulary tabs with "mastered" / "learned" toggles and empty states.
- Progress tab: streak, 30-day minutes and sessions, an accessible 7-day bar chart (spoken labels),
  vault counts and recent sessions. Only server data is shown.
- Data export now includes conversations metadata, mistakes and vocabulary; account deletion
  removes them (verified on the emulator).

## Verification
| Check | Result |
|---|---|
| Backend unit | All pass (new `test/feedback.test.ts`, 9 tests) |
| Emulator integration | All pass (new: transcript storage, single analysis, vault writes, counts, export, deletion) |
| Live (`npm run test:live`) | Passed: schema-valid analysis from the real API |
| Flutter | All pass (new `test/features/learning_test.dart`, 9 tests) |
