# Phase 5: Profile and settings

**Status:** `[x]` Implemented and verified locally (2026-11-09). One external item: reminder
delivery needs Firebase Cloud Messaging (not configured).

## Scope (APP_FLOW §17)
| Feature | Implementation |
|---|---|
| Edit learning preferences (native language, goals, level, daily target, accent) | `PATCH /api/v1/me/preferences` (strict partial schema, same validated merge as onboarding; completion kept). App: `PreferenceEditorScreen` (`/profile/edit/:field`), same options as onboarding; Save enabled only after a valid change; only the edited field is sent |
| Display name | `PATCH /api/v1/me/profile` `displayName` (null clears). App: dialog |
| Time zone | `PATCH /api/v1/me/profile` `timezone`, limited to one change per 24 h (quota day boundary; 429 `TIMEZONE_CHANGE_TOO_SOON`). App: "Use this device's time zone" |
| Preferred tutor | `preferredTutorId` (validated against the catalogue; null = automatic). Recommendations use it only where that tutor fits a scenario at the learner's level |
| Practice reminders | `practiceReminders` opt-in stored. **Delivery blocked:** needs FCM setup (owner) |
| Data export | `GET /api/v1/me/export` (own data only, attachment, no-store). App copies the JSON to the clipboard |
| Sign out, delete account | Unchanged (Phase 3) |
| Subscription management, interface language switching | Phase 9; only English ships today |

## Verification
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | All pass (new `test/features/profile_test.dart`: 9 tests) |
| Backend unit | All pass (new `test/profile-settings.test.ts`: 9 tests) |
| Emulator integration | 25/25 (new: profile patch, time zone limit, preferences edit, export isolation) |
