import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

export 'app_environment.dart';

/// Compile-time configuration, supplied with `--dart-define` or
/// `--dart-define-from-file=env/<environment>.json`.
///
/// SECURITY: every value here is compiled into the app binary and can be
/// extracted. Never put API keys, secrets or credentials in dart-defines.
/// The app only ever receives short-lived, server-issued credentials.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.devUserId,
  });

  /// Reads and validates the compile-time environment.
  /// Throws [ConfigException] when the combination is unsafe or incomplete.
  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
        appEnv: const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        devUserId: const String.fromEnvironment('DEV_USER_ID'),
      );

  factory AppConfig.fromValues({
    required String appEnv,
    required String apiBaseUrl,
    String devUserId = '',
  }) {
    final environment = AppEnvironment.parse(appEnv);

    // Android emulator → host machine. Development only.
    final rawUrl = apiBaseUrl.isEmpty && environment.isDevelopment ? 'http://10.0.2.2:8080' : apiBaseUrl;
    final uri = Uri.tryParse(rawUrl);
    if (rawUrl.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ConfigException('API_BASE_URL must be an absolute URL.');
    }
    if (!environment.isDevelopment && uri.scheme != 'https') {
      throw const ConfigException('API_BASE_URL must use https outside development.');
    }
    if (!environment.isDevelopment && devUserId.isNotEmpty) {
      throw const ConfigException('DEV_USER_ID is only allowed in development.');
    }

    return AppConfig(
      environment: environment,
      apiBaseUrl: rawUrl.endsWith('/') ? rawUrl.substring(0, rawUrl.length - 1) : rawUrl,
      devUserId: environment.isDevelopment ? (devUserId.isEmpty ? 'dev-user' : devUserId) : null,
    );
  }

  final AppEnvironment environment;

  /// Backend origin, without a trailing slash.
  final String apiBaseUrl;

  /// LEGACY PROTOTYPE ONLY: user id sent to the Express prototype, which accepts
  /// it only with DEV_SKIP_AUTH=true. Always null outside development. Removed
  /// when Firebase Auth is wired (Phase 4).
  final String? devUserId;

  /// Display only. The server is authoritative for all usage limits.
  static const freeDailySecondsDisplay = 600;
}

/// Overridden in `main.dart` with the validated configuration.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden at startup'),
);
