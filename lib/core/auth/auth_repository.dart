import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in identity as the app sees it. Never send [uid] to the backend
/// as proof of identity: the backend derives it from the ID token.
class AuthUser {
  const AuthUser({required this.uid, this.email, this.emailVerified = false});

  final String uid;
  final String? email;
  final bool emailVerified;
}

/// A user-safe authentication failure.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => 'AuthFailure($message)';
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

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  static AuthUser? _map(User? u) => u == null ? null : AuthUser(uid: u.uid, email: u.email, emailVerified: u.emailVerified);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

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
  Future<void> signOut() => _auth.signOut();

  Future<void> _guard(Future<Object?> Function() action) async {
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
      'operation-not-allowed' => const AuthFailure('Email sign-in is not enabled yet.'),
      _ => const AuthFailure('Something went wrong. Please try again.'),
    };

/// Overridden in `main.dart` (Firebase or unavailable) and in tests (fake).
final authRepositoryProvider = Provider<AuthRepository>((ref) => const UnavailableAuthRepository());

final authStateProvider = StreamProvider<AuthUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
