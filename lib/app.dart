import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/branding/app_brand.dart';
import 'core/routing/app_router.dart';
import 'core/session/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/languages.dart';
import 'l10n/app_localizations.dart';

class SpreliaApp extends ConsumerWidget {
  const SpreliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Interface language from the learner's saved preference when supported;
    // otherwise the device locale resolution picks a supported locale.
    final session = ref.watch(sessionProvider).value;
    final locale = session is SignedIn ? localeFor(session.profile.preferences.interfaceLanguage) : null;

    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Shown instead of the app when the build's configuration is invalid
/// (e.g. a staging build without an https API URL). Fails closed.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Center(
              child: Text(
                'This build is misconfigured and cannot start.\n\n$message',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
