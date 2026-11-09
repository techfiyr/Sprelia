import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/errors/app_provider_observer.dart';
import 'core/errors/error_reporter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const ErrorReporter reporter = DebugErrorReporter();
  installGlobalErrorHandlers(reporter);

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on ConfigException catch (e) {
    runApp(ConfigErrorApp(message: e.message));
    return;
  }

  // Phase 4: Firebase.initializeApp(options: <flavor options>) and App Check
  // activation go here, before runApp. See doc/FIREBASE_SETUP.md.

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        errorReporterProvider.overrideWithValue(reporter),
      ],
      observers: [AppProviderObserver(reporter)],
      child: const SpreliaApp(),
    ),
  );
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
