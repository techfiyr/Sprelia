import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakdaily/app.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/config/app_config.dart';
import 'package:speakdaily/core/errors/error_reporter.dart';
import 'package:speakdaily/core/session/session_controller.dart';
import 'package:speakdaily/core/storage/local_storage.dart';
import 'package:speakdaily/core/theme/app_theme.dart';
import 'package:speakdaily/features/account/account_repository.dart';
import 'package:speakdaily/features/learn/data/learning_repository.dart';
import 'package:speakdaily/features/practice/data/catalog_repository.dart';
import 'package:speakdaily/features/profile/data/profile_repository.dart';
import 'package:speakdaily/l10n/app_localizations.dart';

import 'fakes.dart';

final testConfig = AppConfig.fromValues(
  appEnv: 'development',
  apiBaseUrl: 'http://localhost:8080',
  firebaseProjectId: 'demo-sprelia',
  firebaseApiKey: 'demo-key',
  firebaseAppId: '1:000000000000:android:0000000000000000',
  firebaseMessagingSenderId: '000000000000',
  firebaseAuthEmulatorHost: '10.0.2.2:9099',
);

class RecordingErrorReporter implements ErrorReporter {
  final errors = <Object>[];

  @override
  void report(Object error, StackTrace? stackTrace, {String? reason, bool fatal = false}) => errors.add(error);
}

/// Pumps a single widget inside the app theme and localizations.
Future<void> pumpThemed(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ));
}

/// Everything the full app needs, faked. Reuse the same [TestBackend] across
/// two pumps to simulate an app restart (same device storage and server).
class TestBackend {
  TestBackend({FakeAuthRepository? auth, FakeProfileRepository? profiles})
      : auth = auth ?? FakeAuthRepository(),
        profiles = profiles ?? FakeProfileRepository();

  final FakeAuthRepository auth;
  final FakeProfileRepository profiles;
  final catalog = FakeCatalogRepository();
  final account = FakeAccountRepository();
  final learning = FakeLearningRepository();
  final reporter = RecordingErrorReporter();
}

Future<SharedPreferences> freshPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Pumps the full application with test overrides.
Future<void> pumpSpreliaApp(
  WidgetTester tester, {
  required TestBackend backend,
  required SharedPreferences prefs,
  AppConfig? config,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      // A new key forces a completely fresh provider container (app restart).
      key: UniqueKey(),
      overrides: [
        appConfigProvider.overrideWithValue(config ?? testConfig),
        errorReporterProvider.overrideWithValue(backend.reporter),
        authRepositoryProvider.overrideWithValue(backend.auth),
        sharedPreferencesProvider.overrideWithValue(prefs),
        profileRepositoryProvider.overrideWithValue(backend.profiles),
        catalogRepositoryProvider.overrideWithValue(backend.catalog),
        accountRepositoryProvider.overrideWithValue(backend.account),
        learningRepositoryProvider.overrideWithValue(backend.learning),
        feedbackPollIntervalProvider.overrideWithValue(Duration.zero),
        deviceTimeZoneProvider.overrideWithValue(() async => 'Asia/Dhaka'),
      ],
      retry: (_, _) => null,
      child: const SpreliaApp(),
    ),
  );
  await tester.pumpAndSettle();
}
