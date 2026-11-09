# Protected files

Do not modify these without explicit approval from the project owner. If a task
seems to require it, stop and explain why.

## Agent rules and approved specs
- `CLAUDE.md`, `.agents/*`: agent instructions.
- `doc/*`: approved product, flow, brand and design documents.

## Security boundaries
- `firestore.rules`, `firestore.indexes.json`, `firebase.json`.
- `backend/src/config/env.ts`: environment validation, including the production guards.
- `backend/src/modules/auth/*`: ID token verification and the auth middleware.
- `backend/src/common/logger.ts`: log redaction list. You may add paths; never remove any.
- `backend/src/tokens.ts`: Gemini ephemeral token constraints (legacy prototype).
- `backend/src/modules/users/profile.routes.ts`, `user.schemas.ts` and the repositories (ownership and validation).
- `backend/test/integration/firestore.rules.test.ts` (may be extended; never weakened).
- `lib/core/routing/app_router.dart` `sessionRedirect` (access rules) and `lib/core/auth/*`.
- `android/app/src/debug/res/xml/network_security_config.xml` (cleartext scope).
- Future: usage, subscription, entitlement and webhook modules.

## Contracts
- `lib/core/services/realtime/realtime_provider.dart`: realtime provider contract.
  Changing it affects every vendor implementation.
- `lib/core/config/app_config.dart`: environment validation rules.

## Platform and identity
- `android/app/src/main/AndroidManifest.xml`: permissions and the app label.
- `android/app/build.gradle.kts` and `ios/Runner.xcodeproj/project.pbxproj`: application IDs, signing.
- `ios/Runner/Info.plist`: permission strings, display name.

## Never in git (and never created by agents)
`.env`, `.env.*` (except `.env.example`), API keys, service-account JSON, keystores,
`key.properties`, `google-services.json`, `GoogleService-Info.plist`,
`lib/firebase_options*.dart`. `.gitignore` enforces this; do not loosen it.
