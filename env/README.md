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
| `FIREBASE_PROJECT_ID` | outside development | The project **ID**, not the number. `sprelia` is **production only**: refused in development and staging builds. |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` | with Firebase | From the Firebase app config. Public identifiers, but real values still only go in gitignored files or CI. |
| `FIREBASE_AUTH_EMULATOR_HOST` | no | `host:port`. **Development only.** Required for `demo-*` projects. |
| `DEV_USER_ID` | no | Development only (legacy prototype). Rejected in staging/production. |

`development.json` targets the **Firebase Emulator Suite** (`demo-sprelia`). Its Firebase
values are placeholders that only the emulator accepts; they are not credentials.

`staging.json`, `production.json` and `*.local.json` are gitignored. Create them from the
`*.example.json` files. See `doc/FIREBASE_SETUP.md` for the environment strategy (production `sprelia`, separate development project, emulators).

**Everything here is compiled into the app binary and can be extracted. Never put
secrets, server API keys, tokens or credentials here.**
