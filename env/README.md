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
| `DEV_USER_ID` | no | Development only (legacy prototype). Rejected in staging/production. |

**These values are compiled into the app and can be extracted from the binary.
Never put API keys, secrets, tokens or credentials here.**

`staging.json` and `production.json` are created from the `*.example.json` files
once the Cloud Run URLs exist. They contain no secrets, but are gitignored so a
local edit cannot silently ship to a release build.
