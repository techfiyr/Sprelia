# Protected files

Do not modify these without explicit approval from the project owner:

- `.agents/*`: agent instructions.
- `lib/core/services/realtime/realtime_provider.dart`: provider contract.
  Changing it affects every vendor implementation.
- `backend/src/tokens.ts`: ephemeral token constraints (security boundary).
- `android/app/src/main/AndroidManifest.xml` permissions.
- `firestore.rules` (once added).
- Any file holding signing config, keystores, `google-services.json`, or `GoogleService-Info.plist`.

Never commit `.env`, API keys, or keystores.
