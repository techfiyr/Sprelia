import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../auth/auth_repository.dart';
import '../config/app_config.dart';

/// Initializes Firebase from the validated [AppConfig] and returns the auth
/// repository to use. Uses Dart-side options (no google-services.json in git).
///
/// Phase 4 adds App Check activation, Crashlytics and Analytics here.
Future<AuthRepository> initializeFirebase(AppConfig config) async {
  final firebase = config.firebase;
  if (firebase == null) return const UnavailableAuthRepository();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: firebase.apiKey,
      appId: firebase.appId,
      messagingSenderId: firebase.messagingSenderId,
      projectId: firebase.projectId,
    ),
  );
  final auth = FirebaseAuth.instance;
  if (firebase.usesEmulator) {
    // AppConfig guarantees this only happens in development builds.
    final (host, port) = firebase.authEmulatorAddress;
    await auth.useAuthEmulator(host, port);
  }
  return FirebaseAuthRepository(auth);
}
