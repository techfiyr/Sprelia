import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/app.dart';
import 'package:speakdaily/core/config/app_config.dart';
import 'package:speakdaily/core/errors/error_reporter.dart';
import 'package:speakdaily/core/theme/app_theme.dart';

final testConfig = AppConfig.fromValues(appEnv: 'development', apiBaseUrl: 'http://localhost:8080');

class RecordingErrorReporter implements ErrorReporter {
  final errors = <Object>[];

  @override
  void report(Object error, StackTrace? stackTrace, {String? reason, bool fatal = false}) => errors.add(error);
}

/// Pumps a single widget inside the app theme.
Future<void> pumpThemed(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)));
}

/// Pumps the full application with test overrides.
Future<void> pumpSpreliaApp(WidgetTester tester, {ErrorReporter? reporter}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        errorReporterProvider.overrideWithValue(reporter ?? RecordingErrorReporter()),
      ],
      child: const SpreliaApp(),
    ),
  );
  await tester.pumpAndSettle();
}
