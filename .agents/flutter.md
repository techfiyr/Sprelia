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
- **Assets**: follow `doc/ASSET_LIBRARY.md`. Reference files only through `AppAssets`
  (`lib/core/assets/app_assets.dart`) and load only entries where `isUsable` is true.
  Tutor images render only through `TutorAvatar`. The final logo and avatars do not exist
  yet: `BrandLogo` and `TutorAvatar` show labelled placeholders. Never ship generated,
  invented or unlicensed assets. `assets/tutors/img_tutor_*.jpeg` are unapproved candidates.
- **Errors**: global handlers in `main.dart`, `AppProviderObserver` for provider
  failures, `AppErrorState` for display. Never render raw exceptions.
- **Audio**: mic input is PCM16 mono 16 kHz (`record`); output is PCM16 mono 24 kHz
  (`flutter_pcm_sound`). Ask for microphone permission only when the user starts their
  first conversation.
- **Strings**: user-facing text goes in `lib/l10n/app_en.arb` and is read with `context.l10n`
  (generated `AppLocalizations`). Phase 1 screens (learn, progress, feedback, conversation) still
  have inline English to migrate. Never build sentences by concatenation; use ARB placeholders and plurals.
- **Session and access**: never navigate based on auth state inside widgets. `sessionRedirect`
  in `app_router.dart` is the single rule; refresh the session with
  `ref.read(sessionProvider.notifier).reload()`.
- **Data access**: screens read repositories through providers (`profileRepositoryProvider`,
  `catalogRepositoryProvider`, `authRepositoryProvider`) so tests can override them with fakes.
- Run `flutter analyze` and `flutter test` before finishing a change.
