import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/auth_repository.dart';
import '../config/app_config.dart';
import '../errors/error_reporter.dart';

/// Returns an App Check token for the `X-Firebase-AppCheck` header, or null.
typedef AppCheckTokenSource = Future<String?> Function();

Future<String?> noAppCheckToken() async => null;

/// Services created at startup.
class FirebaseServices {
  const FirebaseServices({required this.auth, this.appCheckToken = noAppCheckToken});

  final AuthRepository auth;
  final AppCheckTokenSource appCheckToken;
}

/// Initializes Firebase from the validated [AppConfig] (Dart-side options from
/// dart-defines; no google-services.json or GoogleService-Info.plist in git),
/// then App Check and Google sign-in where configured.
Future<FirebaseServices> initializeFirebase(AppConfig config, {ErrorReporter? reporter}) async {
  final firebase = config.firebase;
  if (firebase == null) return const FirebaseServices(auth: UnavailableAuthRepository());

  final isIos = defaultTargetPlatform == TargetPlatform.iOS;
  if (isIos && firebase.iosAppId == null) {
    throw const ConfigException('FIREBASE_IOS_APP_ID is required for iOS builds (register the iOS app first).');
  }
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: isIos ? (firebase.iosApiKey ?? firebase.apiKey) : firebase.apiKey,
      appId: isIos ? firebase.iosAppId! : firebase.appId,
      messagingSenderId: firebase.messagingSenderId,
      projectId: firebase.projectId,
      iosBundleId: isIos ? firebase.iosBundleId : null,
    ),
  );

  final auth = FirebaseAuth.instance;
  if (firebase.usesEmulator) {
    // AppConfig guarantees this only happens in development builds.
    final (host, port) = firebase.authEmulatorAddress;
    await auth.useAuthEmulator(host, port);
  }

  // App Check: Play Integrity / App Attest in release builds, debug providers in debug
  // builds (their debug token must be registered in the Console by the owner). Never
  // with the emulator. A failure here is reported, not fatal: the backend decides
  // (APP_CHECK_MODE) whether requests without a valid token are allowed.
  var appCheckToken = noAppCheckToken;
  if (config.appCheckEnabled && !firebase.usesEmulator) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode ? const AndroidPlayIntegrityProvider() : const AndroidDebugProvider(),
        providerApple: kReleaseMode ? const AppleAppAttestWithDeviceCheckFallbackProvider() : const AppleDebugProvider(),
      );
      appCheckToken = () => FirebaseAppCheck.instance.getToken();
    } catch (e, st) {
      reporter?.report(e, st, reason: 'App Check activation failed');
    }
  }

  // Google sign-in needs the Web OAuth client ID (Android serverClientId) and, on iOS,
  // the iOS client ID. Both exist only after the owner enables the Google provider.
  GoogleSignIn? google;
  final googleReady = firebase.googleSignInConfigured && (!isIos || firebase.googleIosClientId != null);
  if (googleReady) {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: isIos ? firebase.googleIosClientId : null,
        serverClientId: firebase.googleServerClientId,
      );
      google = GoogleSignIn.instance;
    } catch (e, st) {
      reporter?.report(e, st, reason: 'Google sign-in initialization failed');
    }
  }

  return FirebaseServices(auth: FirebaseAuthRepository(auth, google: google), appCheckToken: appCheckToken);
}
