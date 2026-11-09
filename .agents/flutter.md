# Flutter conventions

- **State**: Riverpod 3 (`flutter_riverpod`) with `Notifier` / `AsyncNotifier` / `Provider`.
  App-wide values (`appConfigProvider`, `errorReporterProvider`) are overridden in
  `main.dart`, and tests override them the same way.
- **Navigation**: GoRouter in `lib/core/routing/app_router.dart`. Paths live in `AppRoutes`.
  The tabs sit in a `StatefulShellRoute`. Focused flows are top-level routes above the shell.
  The live conversation must never be an ordinary tab.
- **HTTP**: Dio via `apiClientProvider` (`lib/core/services/api_client.dart`). Map errors
  with `AppFailure.from`.
- **Layout**: feature-first. `lib/features/<feature>/` holds that feature's screens,
  widgets, controllers and repositories. Shared code goes in `lib/core/`.
- **Config**: `AppConfig.fromEnvironment()` reads `--dart-define-from-file=env/<env>.json`
  and fails closed. Never put secrets there.
- **Theme**: Sprelia light theme in `lib/core/theme/`. Raw tokens (`AppColors`) are used
  only inside `lib/core/theme/`. Features use `context.colors`, `context.palette`,
  `context.textStyles`, `AppSpacing`, `Gap` and `AppRadius`. A dark theme must be addable
  by providing a second `ThemeData` and `AppPalette` only.
- **Components**: `lib/core/widgets/widgets.dart`. Extend these rather than duplicating.
- **Assets**: final logo, tutor portraits and Inter font files do not exist yet.
  `BrandLogo` and `TutorAvatar` are labelled placeholders. Never ship generated or
  invented brand assets.
- **Errors**: global handlers in `main.dart`, `AppProviderObserver` for provider
  failures, `AppErrorState` for display. Never render raw exceptions.
- **Audio**: mic input is PCM16 mono 16 kHz (`record`); output is PCM16 mono 24 kHz
  (`flutter_pcm_sound`). Ask for microphone permission only when the user starts their
  first conversation.
- **Strings**: still inline (English). Phase 2 moves them to ARB files (gen-l10n). Write new
  strings so they are easy to extract: no string concatenation for sentences.
- Run `flutter analyze` and `flutter test` before finishing a change.
