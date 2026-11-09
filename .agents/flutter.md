# Flutter conventions

- State: Riverpod (`flutter_riverpod`), with `Notifier` / `AsyncNotifier`. No global singletons
  except platform plugins.
- Navigation: GoRouter, with routes defined in `lib/core/routing/app_router.dart`.
- HTTP: Dio through `apiClientProvider` (`lib/core/services/api_client.dart`).
- Layout: feature-first. `lib/features/<feature>/` holds that feature's screens,
  widgets and controllers. Shared code goes in `lib/core/`.
- Config: compile-time `--dart-define` values in `lib/core/config/app_config.dart`.
  Never hardcode secrets.
- Theme: premium light theme in `lib/core/theme/`. Use `Theme.of(context)` tokens,
  not raw colors, in features.
- Audio: mic input is PCM16 mono 16 kHz (`record`), and output is PCM16 mono
  24 kHz (`flutter_pcm_sound`).
- Ask for microphone permission only when the user starts their first conversation.
- Run `flutter analyze` and `flutter test` before finishing a change.
