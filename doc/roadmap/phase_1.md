# Sprelia — Execute Phase 1: Application and Backend Foundation

The architecture and implementation plan have been reviewed and approved.

Now implement Phase 1 only.

## Flutter

Prepare the existing Flutter application with:

- Feature-first folder architecture.
- Riverpod configuration.
- GoRouter configuration.
- Centralized brand colors and typography.
- Light application theme.
- Reusable buttons, cards, inputs and loading components.
- Environment configuration.
- Application-level error handling.

Use the approved BRAND.md and DESIGN_SYSTEM.md.

Do not invent final logo or tutor assets if they are not available. Use clearly identified placeholders.

## Backend

Create a separate backend directory inside the existing repository.

Use:

- Node.js.
- TypeScript.
- Express or Fastify, choosing one and explaining why.
- Zod for request validation.
- Firebase Admin SDK.
- Structured logging.
- Environment-based configuration.
- Unit testing.

Create:

- Health-check endpoint.
- API versioning.
- Centralized error handling.
- Firebase ID token verification middleware.
- Request validation middleware.
- Basic authenticated test endpoint.

Suggested endpoints:

GET /api/v1/health

GET /api/v1/me

The health endpoint should not expose secrets or internal infrastructure details.

## Security

- Add appropriate .gitignore entries.
- Create .env.example with placeholder values only.
- Never create or commit real credentials.
- Never expose Gemini API keys.
- Do not let clients modify protected user data.
- Add tests for unauthenticated and invalid-token requests.

## Firebase

Prepare the Firebase integration structure and document the required configuration.

Do not create or modify a production Firebase project without explicit approval.

Do not invent Firebase credentials.

## Documentation

Update:

- CLAUDE.md
- .agents/architecture.md
- .agents/security.md
- .agents/development.md

Document all implemented decisions.

## Completion requirements

After implementation:

1. Run Flutter analyzer.
2. Run Flutter tests.
3. Run backend tests.
4. Run TypeScript type checking.
5. Verify the backend health endpoint locally.
6. Review security-sensitive changes.
7. List created and modified files.
8. Document commands to run Flutter and backend.
9. Report any remaining issues.

Do not proceed to Gemini voice integration, subscriptions, advertising or production deployment.

Stop and wait for approval after Phase 1 is complete.
---

# Completion record — Phase 1

**Status:** Completed. Delivered on branch `phase-1-foundation` (commits `7643ba5`, `c72774f`, both pushed).
**Verified:** 2026-11-09, by an audit of the repository and a fresh run of every check (Phase 2 close-out).
**Approval:** Owner approved Phase 1 when issuing `phase_2.md` ("Phase 1 has been reviewed and is approved").

## Task status

### Flutter
- [x] Feature-first folder architecture: `lib/core/*`, `lib/features/<feature>/`.
- [x] Riverpod configuration: `ProviderScope` with overrides and observer in `lib/main.dart`.
- [x] GoRouter configuration: `lib/core/routing/app_router.dart` (5-tab `StatefulShellRoute`, not-found route).
- [x] Centralized brand colours and typography: `lib/core/theme/` (BRAND.md palette, DESIGN_SYSTEM scale).
- [x] Light theme: `AppTheme.light()`.
- [x] Reusable buttons, cards, inputs, loading: `lib/core/widgets/`.
- [x] Environment configuration: `AppConfig` and `env/*.json` (fails closed; https outside development).
- [x] Application-level error handling: `AppFailure`, `ErrorReporter`, `AppProviderObserver`, global handlers.
- [x] Placeholders clearly identified: `BrandLogo` and `TutorAvatar` are labelled "(placeholder)".

### Backend
- [x] Backend directory. Note: the existing `backend/` folder was reused. The Fastify API
  (`src/main.ts`, `src/app.ts`, `src/modules/*`) sits beside the legacy Express voice
  prototype (`src/server.ts`), which is still run with `npm run dev:prototype`.
- [x] Framework chosen and explained: **Fastify 5** (`.agents/architecture.md`).
- [x] Zod request validation middleware: `src/common/validate.ts`.
- [x] Firebase Admin SDK with ID token verification middleware: `src/modules/auth/*`.
- [x] Structured logging with redaction: `src/common/logger.ts`.
- [x] Environment configuration with production guards: `src/config/env.ts`.
- [x] Health endpoint, API versioning (`/api/v1`), centralized error handling, authenticated `/api/v1/me`.
- [x] Unit tests (Vitest).

### Security
- [x] `.gitignore` hardened. `.env.example` contains placeholders only. No credentials committed (secret scan clean).
- [x] No Gemini keys in the app. Clients cannot modify protected data (read-only `/me`; Firestore denies all).
- [x] Tests for unauthenticated and invalid-token requests.

### Firebase
- [x] Integration structure (`firebase.json`, deny-all `firestore.rules`, indexes) and `doc/FIREBASE_SETUP.md`.
- [x] No production project created or modified by the agent.

### Documentation
- [x] `CLAUDE.md`, `.agents/architecture.md`, `.agents/security.md`, `.agents/development.md`
  (plus `AGENTS.md`, `flutter.md`, `protected-files.md`).

### Completion requirements
- [x] Analyzer, Flutter tests, backend tests and typecheck passed. Health endpoint verified on a live server.
  Security review done. Files listed. Run commands documented. Issues reported.

### Added during Phase 1 (owner decisions)
- [x] App identity switched to `com.techfiyr.sprelia` with visible name "Sprelia" (commit `c72774f`),
  to match the Android app registered in Firebase project `sprelia`.

## Test results at Phase 1 delivery
Flutter 36/36; backend 46/46; typecheck clean; debug APK built.

## Issues raised at Phase 1 and their status
| Issue | Status |
|---|---|
| Brand colour contrast failures | Fixed in Phase 2 (BRAND §12) |
| `APP_DEVELOPMENT.md` / `BRAND.md` truncated | Completed in Phase 2; pending owner review |
| Inter not bundled | Fixed in Phase 2 |
| Voice prototype on Express, superseded model IDs, v1alpha tokens | Open, Phase 6 |
| `TRUST_PROXY_HOPS=1` required on Cloud Run | Open (deployment) |
| Release builds signed with debug key | Open, Phase 10 |
| 4 moderate transitive npm advisories (firebase-admin) | Open, no non-breaking fix |
| Unapproved tutor images (`assets/tutors/img_tutor_*.jpeg`) were swept into commit `7643ba5` | Open: licence unknown, not bundled; removing them from history needs owner approval |
