import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

export 'app_environment.dart';

/// The single approved Firebase project (owner architecture decision 2026-11-09,
/// superseding the separate development project). Used by development builds
/// (test accounts only, pre-launch) and required for staging and production.
/// No other real project is accepted; `demo-*` projects only with the emulator.
const approvedFirebaseProjectId = 'sprelia';


/// Firebase client configuration (public identifiers, not secrets).
///
/// Values come from dart-defines (see `env/README.md`). Real project values live
/// only in gitignored env files and CI secrets. In development, the app can use
/// the Firebase Emulator Suite with a `demo-*` project, which needs no real
/// project or credentials.
class FirebaseClientConfig {
  const FirebaseClientConfig({
    required this.projectId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    this.authEmulatorHost,
    this.iosAppId,
    this.iosApiKey,
    this.iosBundleId,
    this.googleServerClientId,
    this.googleIosClientId,
  });

  final String projectId;
  final String apiKey;
  final String appId;
  final String messagingSenderId;

  /// `host:port` of the Auth emulator (development only).
  final String? authEmulatorHost;

  /// iOS Firebase app (registered separately; null until the owner registers it).
  final String? iosAppId;
  final String? iosApiKey;
  final String? iosBundleId;

  /// Google sign-in: the Web OAuth client ID (Android `serverClientId`) and the iOS
  /// OAuth client ID. Created when the owner enables the Google provider.
  final String? googleServerClientId;
  final String? googleIosClientId;

  bool get googleSignInConfigured => googleServerClientId != null;

  /// Development build talking to the shared real project (test accounts only).
  bool get usesSharedProject => !usesEmulator && projectId == approvedFirebaseProjectId;

  bool get usesEmulator => authEmulatorHost != null;

  (String, int) get authEmulatorAddress {
    final parts = authEmulatorHost!.split(':');
    return (parts[0], int.parse(parts[1]));
  }
}

/// Compile-time configuration, supplied with `--dart-define` or
/// `--dart-define-from-file=env/<environment>.json`.
///
/// SECURITY: every value here is compiled into the app binary and can be
/// extracted. Never put API keys for paid services, secrets or credentials in
/// dart-defines. Firebase client identifiers are public by design and are
/// protected by Security Rules, App Check and backend authorization.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.devUserId,
    this.firebase,
    this.appCheckEnabled = true,
  });

  /// Reads and validates the compile-time environment.
  /// Throws [ConfigException] when the combination is unsafe or incomplete.
  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
        appEnv: const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        devUserId: const String.fromEnvironment('DEV_USER_ID'),
        firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
        firebaseAppId: const String.fromEnvironment('FIREBASE_APP_ID'),
        firebaseMessagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        firebaseAuthEmulatorHost: const String.fromEnvironment('FIREBASE_AUTH_EMULATOR_HOST'),
        firebaseIosAppId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
        firebaseIosApiKey: const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
        firebaseIosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
        googleServerClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        googleIosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
        appCheckEnabled: const bool.fromEnvironment('APP_CHECK_ENABLED', defaultValue: true),
      );

  factory AppConfig.fromValues({
    required String appEnv,
    required String apiBaseUrl,
    String devUserId = '',
    String firebaseProjectId = '',
    String firebaseApiKey = '',
    String firebaseAppId = '',
    String firebaseMessagingSenderId = '',
    String firebaseAuthEmulatorHost = '',
    String firebaseIosAppId = '',
    String firebaseIosApiKey = '',
    String firebaseIosBundleId = '',
    String googleServerClientId = '',
    String googleIosClientId = '',
    bool appCheckEnabled = true,
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
      firebase: _firebase(
        environment,
        projectId: firebaseProjectId,
        apiKey: firebaseApiKey,
        appId: firebaseAppId,
        messagingSenderId: firebaseMessagingSenderId,
        authEmulatorHost: firebaseAuthEmulatorHost,
        iosAppId: firebaseIosAppId,
        iosApiKey: firebaseIosApiKey,
        iosBundleId: firebaseIosBundleId,
        googleServerClientId: googleServerClientId,
        googleIosClientId: googleIosClientId,
      ),
      // App Check can only be switched off in development builds.
      appCheckEnabled: appCheckEnabled || !environment.isDevelopment,
    );
  }

  static FirebaseClientConfig? _firebase(
    AppEnvironment environment, {
    required String projectId,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String authEmulatorHost,
    String iosAppId = '',
    String iosApiKey = '',
    String iosBundleId = '',
    String googleServerClientId = '',
    String googleIosClientId = '',
  }) {
    final values = [projectId, apiKey, appId, messagingSenderId];
    if (values.every((v) => v.isEmpty) && authEmulatorHost.isEmpty) {
      if (!environment.isDevelopment) {
        throw const ConfigException('Firebase configuration is required outside development.');
      }
      return null; // Development without Firebase: sign-in is unavailable.
    }
    if (values.any((v) => v.isEmpty)) {
      throw const ConfigException(
        'FIREBASE_PROJECT_ID, FIREBASE_API_KEY, FIREBASE_APP_ID and FIREBASE_MESSAGING_SENDER_ID must all be set.',
      );
    }
    // Firebase project IDs: 6–30 chars, lowercase letters/digits/hyphens, start
    // with a letter. This also rejects a project NUMBER pasted by mistake.
    if (!RegExp(r'^[a-z][a-z0-9-]{4,28}[a-z0-9]$').hasMatch(projectId)) {
      throw const ConfigException('FIREBASE_PROJECT_ID must be a Firebase project ID (not the project number).');
    }
    if (!environment.isDevelopment && projectId != approvedFirebaseProjectId) {
      throw const ConfigException('Staging and production builds must use the approved Firebase project.');
    }
    if (!projectId.startsWith('demo-') && projectId != approvedFirebaseProjectId) {
      throw const ConfigException('Only the approved Firebase project (or a demo-* emulator project) is allowed.');
    }
    if (authEmulatorHost.isNotEmpty) {
      if (!environment.isDevelopment) {
        throw const ConfigException('The Firebase emulator is only allowed in development.');
      }
      if (!RegExp(r'^[A-Za-z0-9.\-]+:\d{2,5}$').hasMatch(authEmulatorHost)) {
        throw const ConfigException('FIREBASE_AUTH_EMULATOR_HOST must be host:port.');
      }
    } else if (projectId.startsWith('demo-')) {
      throw const ConfigException('demo-* Firebase projects only work with the emulator.');
    }
    final oauthClient = RegExp(r'^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$');
    for (final id in [googleServerClientId, googleIosClientId]) {
      if (id.isNotEmpty && !oauthClient.hasMatch(id)) {
        throw const ConfigException('GOOGLE_*_CLIENT_ID must be a Google OAuth client ID (…apps.googleusercontent.com).');
      }
    }
    return FirebaseClientConfig(
      projectId: projectId,
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      authEmulatorHost: authEmulatorHost.isEmpty ? null : authEmulatorHost,
      iosAppId: iosAppId.isEmpty ? null : iosAppId,
      iosApiKey: iosApiKey.isEmpty ? null : iosApiKey,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      googleServerClientId: googleServerClientId.isEmpty ? null : googleServerClientId,
      googleIosClientId: googleIosClientId.isEmpty ? null : googleIosClientId,
    );
  }

  final AppEnvironment environment;

  /// Backend origin, without a trailing slash.
  final String apiBaseUrl;

  /// LEGACY PROTOTYPE ONLY: user id sent to the Express prototype, which accepts
  /// it only with DEV_SKIP_AUTH=true. Always null outside development.
  final String? devUserId;

  /// Null only in development builds without Firebase (sign-in unavailable).
  final FirebaseClientConfig? firebase;

  /// Activate Firebase App Check (always on outside development; never with the emulator).
  final bool appCheckEnabled;

  /// The legacy voice prototype may only be launched from development builds.
  bool get voicePrototypeEnabled => environment.isDevelopment;
}

/// Overridden in `main.dart` with the validated configuration.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden at startup'),
);
