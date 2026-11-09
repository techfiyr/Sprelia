import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application-wide error sink.
///
/// Phase 1 logs to the developer console in debug/profile builds only.
/// Phase 4 adds a Crashlytics implementation. Implementations MUST NOT attach
/// transcripts, audio, tokens or personal data (APP_DEVELOPMENT §6).
abstract interface class ErrorReporter {
  void report(Object error, StackTrace? stackTrace, {String? reason, bool fatal = false});
}

class DebugErrorReporter implements ErrorReporter {
  const DebugErrorReporter();

  @override
  void report(Object error, StackTrace? stackTrace, {String? reason, bool fatal = false}) {
    if (kReleaseMode) return;
    developer.log(
      reason ?? (fatal ? 'Fatal error' : 'Error'),
      name: 'app.error',
      error: error,
      stackTrace: stackTrace,
      level: fatal ? 1200 : 1000,
    );
  }
}

/// Overridden in `main.dart`; tests may override with a recording fake.
final errorReporterProvider = Provider<ErrorReporter>((ref) => const DebugErrorReporter());
