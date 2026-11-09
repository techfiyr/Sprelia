import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_reporter.dart';

/// Reports every provider failure (thrown during build or emitted by a
/// Future/Stream provider) to the [ErrorReporter]. UI still renders the
/// failure through `AsyncValue`; this only guarantees nothing fails silently.
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver(this._reporter);

  final ErrorReporter _reporter;

  @override
  void providerDidFail(ProviderObserverContext context, Object error, StackTrace stackTrace) {
    _reporter.report(error, stackTrace, reason: 'Provider failed: ${context.provider.name ?? context.provider.runtimeType}');
  }
}
