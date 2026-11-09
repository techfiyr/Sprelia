# Flutter build environments

Each file is passed to Flutter with `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/development.json
flutter build appbundle --release --dart-define-from-file=env/staging.json
```

| Key | Required | Notes |
|---|---|---|
| `APP_ENV` | yes | `development`, `staging` or `production` |
| `API_BASE_URL` | outside development | Absolute URL. Must be `https` outside development. Defaults to `http://10.0.2.2:8080` (Android emulator → host) in development. |
| `FIREBASE_PROJECT_ID` | outside development | The project **ID**, not the number. Single approved project (owner decision 2026-11-09): **`sprelia`** for development (pre-launch, test accounts only), staging and production; `demo-*` only with the emulator. Any other project is refused. |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` | with Firebase | From the Firebase app config. Public identifiers, but real values still only go in gitignored files or CI. |
| `FIREBASE_AUTH_EMULATOR_HOST` | no | `host:port`. **Development only.** Required for `demo-*` projects. |
| `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_BUNDLE_ID` | iOS builds | From the iOS Firebase app (not registered yet). `FIREBASE_IOS_API_KEY` defaults to `FIREBASE_API_KEY`. |
| `GOOGLE_SERVER_CLIENT_ID` | for Google sign-in | Web OAuth client ID (`…apps.googleusercontent.com`), Android `serverClientId`. Exists only after the Google provider is enabled. Without it the Google button is disabled. |
| `GOOGLE_IOS_CLIENT_ID` | Google sign-in on iOS | iOS OAuth client ID. iOS also needs its reversed client ID as a URL scheme in `Info.plist`. |
| `APP_CHECK_ENABLED` | no | Default `true`. Can only be `false` in development; never active with the emulator. Debug builds use the App Check debug provider (register its debug token in the Console). |
| `DEV_USER_ID` | no | Development only (legacy prototype). Rejected in staging/production. |

`development.json` targets the **Firebase Emulator Suite** (`demo-sprelia`). Its Firebase
values are placeholders that only the emulator accepts; they are not credentials.

`staging.json`, `production.json` and `*.local.json` are gitignored. Create them from the
`*.example.json` files. Development against the shared project uses
`env/development-firebase.local.json` (gitignored; `flutter run --dart-define-from-file=env/development-firebase.local.json`).
See `doc/FIREBASE_SETUP.md` for the environment strategy (single project `sprelia`, emulators for tests).

**Everything here is compiled into the app binary and can be extracted. Never put
secrets, server API keys, tokens or credentials here.**
