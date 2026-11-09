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