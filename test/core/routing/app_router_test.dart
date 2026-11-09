import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/branding/app_brand.dart';
import 'package:speakdaily/core/routing/app_router.dart';
import 'package:speakdaily/core/session/session_controller.dart';
import 'package:speakdaily/features/onboarding/onboarding_screen.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

GoRouter routerOf(WidgetTester tester) {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  return container.read(routerProvider);
}

const _user = AuthUser(uid: 'uid-1', email: 'learner@example.com');
const _onboarded = UserProfile(uid: 'uid-1', timezone: 'Asia/Dhaka', onboardingStatus: OnboardingStatus.completed);
const _fresh = UserProfile(uid: 'uid-1', timezone: 'Asia/Dhaka', onboardingStatus: OnboardingStatus.notStarted);

void main() {
  group('sessionRedirect', () {
    const loading = AsyncLoading<SessionState>();
    const out = AsyncData<SessionState>(SignedOut());
    const needsOnboarding = AsyncData<SessionState>(SignedIn(_user, _fresh));
    const ready = AsyncData<SessionState>(SignedIn(_user, _onboarded));

    test('loading → splash', () {
      expect(sessionRedirect(loading, AppRoutes.home), AppRoutes.splash);
      expect(sessionRedirect(loading, AppRoutes.splash), isNull);
    });

    test('error → splash (retry lives there)', () {
      expect(sessionRedirect(AsyncError<SessionState>(Exception('x'), StackTrace.empty), AppRoutes.home), AppRoutes.splash);
    });

    test('signed out may only see welcome, the sample lesson and sign-in', () {
      expect(sessionRedirect(out, AppRoutes.welcome), isNull);
      expect(sessionRedirect(out, AppRoutes.signIn), isNull);
      expect(sessionRedirect(out, AppRoutes.guestLesson), isNull);
      expect(sessionRedirect(out, AppRoutes.home), AppRoutes.welcome);
      expect(sessionRedirect(out, AppRoutes.prepare('emma')), AppRoutes.welcome);
      expect(sessionRedirect(out, AppRoutes.onboarding), AppRoutes.welcome);
    });

    test('signed in without onboarding is held in onboarding', () {
      expect(sessionRedirect(needsOnboarding, AppRoutes.home), AppRoutes.onboarding);
      expect(sessionRedirect(needsOnboarding, AppRoutes.tutors), AppRoutes.onboarding);
      expect(sessionRedirect(needsOnboarding, AppRoutes.onboarding), isNull);
      // Onboarding comes after the subscription gate: a subscribed account reaches it.
      const subscribed = AsyncData<bool?>(true);
      expect(sessionRedirect(needsOnboarding, AppRoutes.home, entitlement: subscribed), AppRoutes.onboarding);
    });

    test('onboarded users skip entry screens', () {
      for (final entry in [AppRoutes.splash, AppRoutes.welcome, AppRoutes.signIn, AppRoutes.onboarding]) {
        expect(sessionRedirect(ready, entry), AppRoutes.home);
      }
      expect(sessionRedirect(ready, AppRoutes.category('travel')), isNull);
      expect(sessionRedirect(ready, AppRoutes.guestLesson), AppRoutes.home);
    });

    test('signed in without an active subscription is held on the paywall (fails closed)', () {
      const unsubscribed = AsyncData<bool?>(false);
      expect(sessionRedirect(ready, AppRoutes.home, entitlement: unsubscribed), AppRoutes.premium);
      expect(sessionRedirect(needsOnboarding, AppRoutes.onboarding, entitlement: unsubscribed), AppRoutes.premium);
      expect(sessionRedirect(ready, AppRoutes.premium, entitlement: unsubscribed), isNull);
      expect(sessionRedirect(ready, AppRoutes.home, entitlement: AsyncError<bool?>('x', StackTrace.empty)), AppRoutes.premium);
      expect(sessionRedirect(ready, AppRoutes.home, entitlement: const AsyncLoading<bool?>()), AppRoutes.splash);
      expect(sessionRedirect(ready, AppRoutes.home, entitlement: const AsyncData<bool?>(true)), isNull);
    });
  });

  testWidgets('signed-out users land on Welcome with the brand tagline', (tester) async {
    await pumpSpreliaApp(tester, backend: TestBackend(), prefs: await freshPrefs());
    expect(find.text(AppBrand.tagline), findsOneWidget);
    expect(find.text('Try a free lesson'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsOneWidget);
  });

  testWidgets('sign-in creates the profile (device time zone) and opens onboarding', (tester) async {
    final backend = TestBackend();
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());

    await tester.tap(find.text('Sign in or create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('auth-email')), 'learner@example.com');
    await tester.enterText(find.byKey(const ValueKey('auth-password')), 'correct-horse');
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(backend.auth.signInCalls.single, ('learner@example.com', 'correct-horse'));
    expect(backend.profiles.createdTimezones, ['Asia/Dhaka']);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('onboarded users go straight to the five-tab Home', (tester) async {
    final backend = TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _onboarded));
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Practice', 'Learn', 'Progress', 'Profile']) {
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)), findsOneWidget);
    }
    expect(find.text('Start Speaking'), findsOneWidget);
  });

  testWidgets('signing out returns to Welcome', (tester) async {
    final backend = TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _onboarded));
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('profile-sign-out')), 200);
    await tester.tap(find.byKey(const ValueKey('profile-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text(AppBrand.tagline), findsOneWidget);
  });

  testWidgets('session failures show a retry instead of an endless spinner', (tester) async {
    final profiles = _FailingProfiles();
    final backend = TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: profiles);
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    expect(find.text("You're offline"), findsOneWidget);

    profiles.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('unknown routes show a recoverable not-found screen', (tester) async {
    final backend = TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _onboarded));
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    routerOf(tester).go('/definitely/not/a/route');
    await tester.pumpAndSettle();
    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
  });

  test('route helpers encode parameters', () {
    expect(AppRoutes.prepare('emma'), '/prepare/emma');
    expect(AppRoutes.prepare('alex', scenarioId: 'job-interviews'), '/prepare/alex?scenario=job-interviews');
    expect(AppRoutes.feedback('a/b?c'), '/feedback/a%2Fb%3Fc');
  });
}

class _FailingProfiles extends FakeProfileRepository {
  bool fail = true;

  @override
  Future<UserProfile?> getProfile() async {
    if (fail) throw networkFailure;
    return super.getProfile();
  }
}
