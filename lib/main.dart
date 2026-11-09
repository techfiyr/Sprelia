import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/assets/app_assets.dart';
import 'core/auth/auth_repository.dart';
import 'core/config/app_config.dart';
import 'core/errors/app_provider_observer.dart';
import 'core/errors/error_reporter.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/services/api_client.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const ErrorReporter reporter = DebugErrorReporter();
  installGlobalErrorHandlers(reporter);
  registerAssetLicenses();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on ConfigException catch (e) {
    runApp(ConfigErrorApp(message: e.message));
    return;
  }

  final FirebaseServices firebase;
  final SharedPreferences prefs;
  try {
    (firebase, prefs) = await (initializeFirebase(config, reporter: reporter), SharedPreferences.getInstance()).wait;
  } on ConfigException catch (e) {
    runApp(ConfigErrorApp(message: e.message));
    return;
  } catch (e, st) {
    reporter.report(e, st, reason: 'Startup failed', fatal: true);
    runApp(const ConfigErrorApp(message: 'The app could not start. Please try again later.'));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        errorReporterProvider.overrideWithValue(reporter),
        authRepositoryProvider.overrideWithValue(firebase.auth),
        appCheckTokenProvider.overrideWithValue(firebase.appCheckToken),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      observers: [AppProviderObserver(reporter)],
      // Failed requests are retried by the user (retry buttons), never silently
      // in a loop, so the backend is not hammered and errors stay visible.
      retry: (_, _) => null,
      child: const SpreliaApp(),
    ),
  );
}

/// Adds bundled third-party asset licences (Inter, SIL OFL 1.1) to the in-app
/// licences page (`showLicensePage`). Package licences are added by Flutter.
void registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(AppAssets.interLicense.path);
    yield LicenseEntryWithLineBreaks(const ['Inter (font)'], text);
  });
}

/// Routes every uncaught error to [reporter] so nothing fails silently.
@visibleForTesting
void installGlobalErrorHandlers(ErrorReporter reporter) {
  // Errors inside the Flutter framework (build, layout, paint, gestures).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.report(details.exception, details.stack, reason: 'Flutter framework error', fatal: false);
  };

  // Uncaught asynchronous errors outside the framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(error, stack, reason: 'Uncaught async error', fatal: true);
    return true;
  };

  // In release builds, show a neutral placeholder instead of the red/grey error box.
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Center(child: Icon(Icons.error_outline_rounded));
  }
}
