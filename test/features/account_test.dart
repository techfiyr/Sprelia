import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/errors/app_failure.dart';
import 'package:speakdaily/core/routing/app_router.dart';
import 'package:speakdaily/core/session/session_controller.dart';
import 'package:speakdaily/core/widgets/widgets.dart';
import 'package:speakdaily/features/account/account_repository.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// Phase 3 account flows: email verification, Google sign-in, session restore and
/// account deletion. All Firebase and backend calls are faked.
const _onboarded = UserProfile(
  uid: 'uid-1',
  email: 'learner@example.com',
  timezone: 'Asia/Dhaka',
  onboardingStatus: OnboardingStatus.completed,
);
const _passwordUser = AuthUser(uid: 'uid-1', email: 'learner@example.com', emailVerified: true, providerIds: ['password']);
const _unverified = AuthUser(uid: 'uid-1', email: 'learner@example.com', providerIds: ['password']);

Future<void> _openProfile(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.byKey(const ValueKey('profile-delete-account')), 200);
}

void main() {
  group('sessionRedirect: email verification', () {
    const verify = AsyncData<SessionState>(NeedsEmailVerification(_unverified));

    test('unverified email/password accounts are held on the verification screen', () {
      expect(sessionRedirect(verify, AppRoutes.home), AppRoutes.verifyEmail);
      expect(sessionRedirect(verify, AppRoutes.onboarding), AppRoutes.verifyEmail);
      expect(sessionRedirect(verify, AppRoutes.signIn), AppRoutes.verifyEmail);
      expect(sessionRedirect(verify, AppRoutes.verifyEmail), isNull);
    });

    test('verified users never stay on the verification screen', () {
      const ready = AsyncData<SessionState>(SignedIn(_passwordUser, _onboarded));
      expect(sessionRedirect(ready, AppRoutes.verifyEmail), AppRoutes.home);
    });

    test('only unverified password accounts need verification', () {
      expect(_unverified.needsEmailVerification, isTrue);
      expect(_passwordUser.needsEmailVerification, isFalse);
      expect(const AuthUser(uid: 'g', providerIds: ['google.com']).needsEmailVerification, isFalse);
      expect(const AuthUser(uid: 'g', providerIds: ['password', 'google.com']).needsEmailVerification, isFalse);
    });
  });

  group('Email verification', () {
    Future<TestBackend> createAccount(WidgetTester tester) async {
      final backend = TestBackend();
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('auth-email')), 'learner@example.com');
      await tester.enterText(find.byKey(const ValueKey('auth-password')), 'long-enough-1');
      await tester.tap(find.byKey(const ValueKey('auth-submit')));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('a new account gets a verification email and waits on the verification screen', (tester) async {
      final backend = await createAccount(tester);
      expect(backend.auth.verificationSends, 1);
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.textContaining('learner@example.com'), findsOneWidget);
      expect(backend.profiles.createdTimezones, isEmpty, reason: 'no profile before verification');
    });

    testWidgets('checking before verifying explains; after verifying, onboarding starts', (tester) async {
      final backend = await createAccount(tester);
      await tester.tap(find.byKey(const ValueKey('verify-check')));
      await tester.pumpAndSettle();
      expect(find.textContaining("isn't verified yet"), findsOneWidget);

      backend.auth.verifiedOnServer = true;
      await tester.tap(find.byKey(const ValueKey('verify-check')));
      await tester.pumpAndSettle();
      expect(find.text('Verify your email'), findsNothing);
      expect(backend.profiles.createdTimezones, ['Asia/Dhaka']);
    });

    testWidgets('resend has a cooldown', (tester) async {
      final backend = await createAccount(tester);
      await tester.tap(find.byKey(const ValueKey('verify-resend')));
      await tester.pump();
      expect(backend.auth.verificationSends, 2);
      expect(find.text('Resend in 60s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Resend email'), findsOneWidget);
    });

    testWidgets('a different account can be used (sign out)', (tester) async {
      await createAccount(tester);
      await tester.tap(find.byKey(const ValueKey('verify-sign-out')));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Email'), findsOneWidget);
    });
  });

  group('Google sign-in', () {
    testWidgets('is shown but disabled until configured', (tester) async {
      await pumpSpreliaApp(tester, backend: TestBackend(), prefs: await freshPrefs());
      final button = tester.widget<AppButton>(find.byKey(const ValueKey('auth-google')));
      expect(button.onPressed, isNull);
      expect(find.text('Google sign-in will be available soon.'), findsOneWidget);
    });

    testWidgets('signs in and continues to onboarding without email verification', (tester) async {
      final backend = TestBackend()..auth.googleAvailable = true;
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await tester.tap(find.byKey(const ValueKey('auth-google')));
      await tester.pumpAndSettle();
      expect(backend.auth.googleCalls, 1);
      expect(find.text('Verify your email'), findsNothing);
      expect(backend.profiles.createdTimezones, ['Asia/Dhaka']);
    });

    testWidgets('a cancelled picker is silent; a real failure is shown', (tester) async {
      final backend = TestBackend()
        ..auth.googleAvailable = true
        ..auth.nextGoogleFailure = const AuthCancelled();
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await tester.tap(find.byKey(const ValueKey('auth-google')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      backend.auth.nextGoogleFailure = const AuthFailure('Google sign-in failed. Please try again.');
      await tester.tap(find.byKey(const ValueKey('auth-google')));
      await tester.pumpAndSettle();
      expect(find.text('Google sign-in failed. Please try again.'), findsOneWidget);
    });
  });

  testWidgets('session restore: a session the server rejects is signed out', (tester) async {
    final backend = TestBackend(
      auth: FakeAuthRepository(signedIn: _passwordUser),
      profiles: _RejectingProfiles(),
    );
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    expect(backend.auth.signOutCalls, 1);
    expect(find.text('Continue with Email'), findsOneWidget);
  });

  group('Account deletion', () {
    TestBackend signedIn(AuthUser user) =>
        TestBackend(auth: FakeAuthRepository(signedIn: user), profiles: FakeProfileRepository(profile: _onboarded));

    testWidgets('confirm → password → delete → local data cleared → signed out', (tester) async {
      final backend = signedIn(_passwordUser);
      final prefs = await freshPrefs({'onboarding_draft_v1_uid-1': '{}'});
      await pumpSpreliaApp(tester, backend: backend, prefs: prefs);
      await _openProfile(tester);

      await tester.tap(find.byKey(const ValueKey('profile-delete-account')));
      await tester.pumpAndSettle();
      expect(find.text('Delete your account?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('reauth-password')), 'correct-horse');
      await tester.tap(find.byKey(const ValueKey('reauth-continue')));
      await tester.pumpAndSettle();

      expect(backend.auth.reauthPasswords, ['correct-horse']);
      expect(backend.account.deleteCalls, 1);
      expect(prefs.getString('onboarding_draft_v1_uid-1'), isNull);
      expect(find.text('Continue with Email'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation deletes nothing', (tester) async {
      final backend = signedIn(_passwordUser);
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _openProfile(tester);
      await tester.tap(find.byKey(const ValueKey('profile-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.auth.reauthPasswords, isEmpty);
      expect(backend.account.deleteCalls, 0);
    });

    testWidgets('Google accounts re-authenticate with Google', (tester) async {
      final backend = signedIn(const AuthUser(uid: 'uid-1', email: 'l@gmail.com', emailVerified: true, providerIds: ['google.com']));
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _openProfile(tester);
      await tester.tap(find.byKey(const ValueKey('profile-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
      await tester.pumpAndSettle();
      expect(backend.auth.reauthGoogleCalls, 1);
      expect(backend.account.deleteCalls, 1);
    });

    testWidgets('a wrong password stops before anything is deleted', (tester) async {
      final backend = signedIn(_passwordUser)..auth.nextReauthFailure = mapAuthErrorCode('wrong-password');
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _openProfile(tester);
      await tester.tap(find.byKey(const ValueKey('profile-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('reauth-password')), 'wrong-password');
      await tester.tap(find.byKey(const ValueKey('reauth-continue')));
      await tester.pumpAndSettle();
      expect(backend.account.deleteCalls, 0);
      expect(find.text('Email or password is incorrect.'), findsOneWidget);
    });

    testWidgets('REAUTH_REQUIRED from the server keeps the user signed in with an explanation', (tester) async {
      final backend = signedIn(_passwordUser);
      backend.account.error = const ReauthRequiredFailure();
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _openProfile(tester);
      await tester.tap(find.byKey(const ValueKey('profile-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('reauth-password')), 'correct-horse');
      await tester.tap(find.byKey(const ValueKey('reauth-continue')));
      await tester.pumpAndSettle();
      expect(find.text('For your security, please sign in again to continue.'), findsOneWidget);
      expect(backend.auth.signOutCalls, 0);
    });
  });
}

/// The backend no longer accepts the restored session (revoked, disabled or deleted).
class _RejectingProfiles extends FakeProfileRepository {
  @override
  Future<UserProfile?> getProfile() async => throw const UnauthenticatedFailure();
}
