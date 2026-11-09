import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The signed-in identity as the app sees it. Never send [uid] to the backend
/// as proof of identity: the backend derives it from the ID token.
class AuthUser {
  const AuthUser({required this.uid, this.email, this.emailVerified = false, this.providerIds = const []});

  final String uid;
  final String? email;
  final bool emailVerified;

  /// Linked sign-in providers, e.g. `password`, `google.com`.
  final List<String> providerIds;

  bool get usesPassword => providerIds.contains(EmailAuthProvider.PROVIDER_ID);
  bool get usesGoogle => providerIds.contains(GoogleAuthProvider.PROVIDER_ID);

  /// Email/password accounts must verify their email before using the app (owner
  /// decision D1, recommended). The backend enforces the same rule.
  bool get needsEmailVerification => usesPassword && !emailVerified && !usesGoogle;
}

/// A user-safe authentication failure.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => 'AuthFailure($message)';
}

/// The user closed the Google account picker. Not an error to display.
class AuthCancelled extends AuthFailure {
  const AuthCancelled() : super('');
}

/// Authentication boundary. UI and controllers depend on this interface only.
abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;

  /// A Firebase ID token for `Authorization: Bearer`. Null when signed out.
  Future<String?> idToken({bool forceRefresh = false});

  Future<void> signInWithEmail({required String email, required String password});
  Future<void> createAccountWithEmail({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

/// Account operations beyond the core session (kept separate from [AuthRepository]
/// so the core contract stays small). Obtain it through [accountAuthProvider].
abstract interface class AccountAuth {
  /// True when Google sign-in is configured for this build.
  bool get googleSignInAvailable;

  Future<void> signInWithGoogle();
  Future<void> sendEmailVerification();

  /// Reloads the user from Firebase and refreshes the ID token (so the backend sees
  /// `email_verified` immediately). Returns the refreshed user, or null if signed out.
  Future<AuthUser?> refreshUser();

  /// Re-authentication for sensitive operations (account deletion). Afterwards the ID
  /// token carries a fresh `auth_time`.
  Future<void> reauthenticateWithPassword(String password);
  Future<void> reauthenticateWithGoogle();
}

class UnavailableAccountAuth implements AccountAuth {
  const UnavailableAccountAuth();

  static const _failure = AuthFailure('This option is not available in this build.');

  @override
  bool get googleSignInAvailable => false;
  @override
  Future<void> signInWithGoogle() => Future.error(_failure);
  @override
  Future<void> sendEmailVerification() => Future.error(_failure);
  @override
  Future<AuthUser?> refreshUser() async => null;
  @override
  Future<void> reauthenticateWithPassword(String password) => Future.error(_failure);
  @override
  Future<void> reauthenticateWithGoogle() => Future.error(_failure);
}

/// Used when the build has no Firebase configuration (development only).
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  static const _failure = AuthFailure('Sign-in is not configured in this build.');

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);
  @override
  AuthUser? get currentUser => null;
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => null;
  @override
  Future<void> signInWithEmail({required String email, required String password}) => Future.error(_failure);
  @override
  Future<void> createAccountWithEmail({required String email, required String password}) => Future.error(_failure);
  @override
  Future<void> sendPasswordReset(String email) => Future.error(_failure);
  @override
  Future<void> signOut() async {}
}

class FirebaseAuthRepository implements AuthRepository, AccountAuth {
  /// [google] is null when Google sign-in is not configured for this build.
  FirebaseAuthRepository(this._auth, {GoogleSignIn? google}) : _google = google; // ignore: prefer_initializing_formals

  final FirebaseAuth _auth;
  final GoogleSignIn? _google;

  /// Emits after [refreshUser], because `reload()` is not guaranteed to emit on
  /// every platform.
  final _manual = StreamController<User?>.broadcast();

  static AuthUser? _map(User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email,
          emailVerified: u.emailVerified,
          providerIds: [for (final p in u.providerData) p.providerId],
        );

  /// Sign-in, sign-out and user updates (e.g. email verified), restored from
  /// Firebase's persisted session on startup.
  @override
  Stream<AuthUser?> authStateChanges() {
    late final StreamController<AuthUser?> out;
    final subs = <StreamSubscription<User?>>[];
    out = StreamController<AuthUser?>(
      onListen: () {
        for (final source in [_auth.userChanges(), _manual.stream]) {
          subs.add(source.listen((u) => out.add(_map(u)), onError: out.addError));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        await out.close();
      },
    );
    return out.stream;
  }

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => _auth.currentUser?.getIdToken(forceRefresh);

  @override
  Future<void> signInWithEmail({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<void> createAccountWithEmail({required String email, required String password}) =>
      _guard(() => _auth.createUserWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    try {
      await _google?.signOut();
    } catch (_) {
      // Google sign-out failures must not keep the user signed in to Sprelia.
    }
    await _auth.signOut();
  }

  @override
  bool get googleSignInAvailable => _google != null;

  Future<String> _googleIdToken() async {
    final google = _google;
    if (google == null) throw const AuthFailure('Google sign-in is not available yet.');
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure('Google sign-in failed. Please try again.');
      return idToken;
    } on GoogleSignInException catch (e) {
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled || GoogleSignInExceptionCode.interrupted => const AuthCancelled(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          const AuthFailure('Google sign-in is not set up correctly yet.'),
        GoogleSignInExceptionCode.uiUnavailable => const AuthFailure('Google sign-in is not available on this device.'),
        _ => const AuthFailure('Google sign-in failed. Please try again.'),
      };
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final idToken = await _googleIdToken();
    await _guard(() => _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken)));
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw mapAuthErrorCode('user-not-found');
    await _guard(() => user.sendEmailVerification());
  }

  @override
  Future<AuthUser?> refreshUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await _guard(() async {
      await user.reload();
      await _auth.currentUser?.getIdToken(true);
    });
    final refreshed = _auth.currentUser;
    _manual.add(refreshed);
    return _map(refreshed);
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw mapAuthErrorCode('user-not-found');
    await _guard(() async {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: password));
      await user.getIdToken(true);
    });
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw mapAuthErrorCode('user-not-found');
    final idToken = await _googleIdToken();
    await _guard(() async {
      await user.reauthenticateWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      await user.getIdToken(true);
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw mapAuthErrorCode(e.code);
    }
  }
}

/// Maps Firebase Auth error codes to friendly messages. Wrong-password and
/// unknown-account cases share one message to avoid account enumeration.
AuthFailure mapAuthErrorCode(String code) => switch (code) {
      'invalid-email' => const AuthFailure('Please enter a valid email address.'),
      'user-not-found' || 'wrong-password' || 'invalid-credential' || 'INVALID_LOGIN_CREDENTIALS' =>
        const AuthFailure('Email or password is incorrect.'),
      'email-already-in-use' => const AuthFailure('An account with this email already exists. Try signing in.'),
      'weak-password' => const AuthFailure('Please choose a stronger password (at least 8 characters).'),
      'user-disabled' => const AuthFailure('This account has been disabled.'),
      'too-many-requests' => const AuthFailure('Too many attempts. Please wait a moment and try again.'),
      'network-request-failed' => const AuthFailure("You're offline. Check your connection and try again."),
      'operation-not-allowed' => const AuthFailure('This sign-in method is not enabled yet.'),
      'requires-recent-login' => const AuthFailure('For your security, please sign in again to continue.'),
      'user-mismatch' => const AuthFailure('Please sign in with the account you are currently using.'),
      'account-exists-with-different-credential' =>
        const AuthFailure('An account already exists with this email. Sign in with your email and password first.'),
      'credential-already-in-use' => const AuthFailure('This Google account is already linked to another account.'),
      _ => const AuthFailure('Something went wrong. Please try again.'),
    };

/// Overridden in `main.dart` (Firebase or unavailable) and in tests (fake).
final authRepositoryProvider = Provider<AuthRepository>((ref) => const UnavailableAuthRepository());

/// Account operations for the current build (unavailable without Firebase).
final accountAuthProvider = Provider<AccountAuth>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  if (auth case final AccountAuth account) return account;
  return const UnavailableAccountAuth();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
