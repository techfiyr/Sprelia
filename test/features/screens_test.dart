import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/config/app_config.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const _user = AuthUser(uid: 'uid-1', email: 'learner@example.com');
const _onboarded = UserProfile(
  uid: 'uid-1',
  email: 'learner@example.com',
  displayName: 'Rahim',
  timezone: 'Asia/Dhaka',
  onboardingStatus: OnboardingStatus.completed,
  preferences: LearningPreferences(
    interfaceLanguage: 'en',
    nativeLanguage: 'bn',
    goals: {LearningGoal.career},
    level: EnglishLevel.b1,
    dailyGoalMinutes: 10,
    accent: AccentPreference.british,
  ),
);

TestBackend _signedIn() =>
    TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _onboarded));

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  group('Home dashboard', () {
    testWidgets('shows server data: progress, free time, recommendation, stats', (tester) async {
      await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs());
      expect(find.textContaining('Rahim'), findsOneWidget);
      expect(find.text('4 of 10 minutes'), findsOneWidget);
      expect(find.text('6 min of free speaking time left today'), findsOneWidget);
      expect(find.text('Introductions'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('3-day streak'), 200);
      expect(find.text('3-day streak'), findsOneWidget);
      expect(find.text('4 sessions this week'), findsOneWidget);
    });

    testWidgets('error state offers a retry', (tester) async {
      final backend = _signedIn()..profiles.dashboardError = networkFailure;
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      expect(find.text("You're offline"), findsOneWidget);
      backend.profiles.dashboardError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('4 of 10 minutes'), findsOneWidget);
    });

    testWidgets('Start Speaking opens preparation for the recommendation', (tester) async {
      await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs());
      await tester.tap(find.byKey(const ValueKey('home-start-speaking')));
      await tester.pumpAndSettle();
      expect(find.text('Get ready'), findsOneWidget);
      expect(find.text('Introductions'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing, reason: 'focused full-screen flow');
    });
  });

  group('Practice', () {
    testWidgets('category → scenario → preparation with objectives and vocabulary', (tester) async {
      await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs());
      await _tab(tester, 'Practice');
      expect(find.text('Free conversation'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('category-professional')));
      await tester.pumpAndSettle();
      expect(find.text('Job interviews'), findsOneWidget);
      expect(find.text('Levels A2 – C1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scenario-job-interviews')));
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Give examples'), findsOneWidget);
      expect(find.text('strengths'), findsOneWidget);
      expect(find.text('Voice practice with Alex is coming soon.'), findsOneWidget);
      final start = tester.widget<FilledButton>(
        find.descendant(of: find.byKey(const ValueKey('prepare-start')), matching: find.byType(FilledButton)),
      );
      expect(start.onPressed, isNull);
    });

    testWidgets('changing the tutor keeps the scenario', (tester) async {
      await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs());
      await _tab(tester, 'Practice');
      await tester.tap(find.byKey(const ValueKey('category-professional')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scenario-job-interviews')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('prepare-change-tutor')));
      await tester.pumpAndSettle();
      expect(find.text('Choose your tutor'), findsOneWidget);
      expect(find.text('Voice coming soon'), findsOneWidget, reason: 'Alex has no voice yet');
      await tester.tap(find.byKey(const ValueKey('tutor-emma')));
      await tester.pumpAndSettle();
      expect(find.text('Emma'), findsOneWidget);
      expect(find.text('Job interviews'), findsOneWidget);
    });

    testWidgets('catalogue errors show a retry', (tester) async {
      final backend = _signedIn()..catalog.error = networkFailure;
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _tab(tester, 'Practice');
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('Preparation', () {
    testWidgets('Emma can start the voice prototype in development builds only', (tester) async {
      await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs());
      await tester.tap(find.byKey(const ValueKey('home-start-speaking')));
      await tester.pumpAndSettle();
      final start = tester.widget<FilledButton>(
        find.descendant(of: find.byKey(const ValueKey('prepare-start')), matching: find.byType(FilledButton)),
      );
      expect(start.onPressed, isNotNull);
    });

    testWidgets('production builds never launch the prototype', (tester) async {
      final prod = AppConfig.fromValues(
        appEnv: 'production',
        apiBaseUrl: 'https://api.example.com',
        firebaseProjectId: 'sprelia',
        firebaseApiKey: 'k',
        firebaseAppId: '1:1:android:1',
        firebaseMessagingSenderId: '1',
      );
      await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs(), config: prod);
      await tester.tap(find.byKey(const ValueKey('home-start-speaking')));
      await tester.pumpAndSettle();
      final start = tester.widget<FilledButton>(
        find.descendant(of: find.byKey(const ValueKey('prepare-start')), matching: find.byType(FilledButton)),
      );
      expect(start.onPressed, isNull);
    });
  });

  group('Sign in', () {
    Future<void> openSignIn(WidgetTester tester, TestBackend backend) async {
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();
    }

    testWidgets('validates input before calling Firebase', (tester) async {
      final backend = TestBackend();
      await openSignIn(tester, backend);
      await tester.enterText(find.byKey(const ValueKey('auth-email')), 'not-an-email');
      await tester.enterText(find.byKey(const ValueKey('auth-password')), 'short');
      await tester.tap(find.byKey(const ValueKey('auth-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(backend.auth.signInCalls, isEmpty);
    });

    testWidgets('shows a non-enumerating error for bad credentials', (tester) async {
      final backend = TestBackend()..auth.nextFailure = mapAuthErrorCode('user-not-found');
      await openSignIn(tester, backend);
      await tester.enterText(find.byKey(const ValueKey('auth-email')), 'nobody@example.com');
      await tester.enterText(find.byKey(const ValueKey('auth-password')), 'whatever123');
      await tester.tap(find.byKey(const ValueKey('auth-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(mapAuthErrorCode('wrong-password').message, mapAuthErrorCode('user-not-found').message);
    });

    testWidgets('can switch to account creation', (tester) async {
      final backend = TestBackend();
      await openSignIn(tester, backend);
      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('auth-email')), 'new@example.com');
      await tester.enterText(find.byKey(const ValueKey('auth-password')), 'long-enough-1');
      await tester.tap(find.byKey(const ValueKey('auth-submit')));
      await tester.pumpAndSettle();
      expect(backend.auth.createCalls.single.$1, 'new@example.com');
    });

    testWidgets('password reset confirms without revealing whether an account exists', (tester) async {
      final backend = TestBackend();
      await openSignIn(tester, backend);
      await tester.enterText(find.byKey(const ValueKey('auth-email')), 'someone@example.com');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('If an account exists for someone@example.com'), findsOneWidget);
      expect(backend.auth.resetCalls, ['someone@example.com']);
    });
  });

  testWidgets('sign-in is disabled when the build has no Firebase config', (tester) async {
    final noFirebase = AppConfig.fromValues(appEnv: 'development', apiBaseUrl: 'http://localhost:8080');
    await pumpSpreliaApp(tester, backend: TestBackend(), prefs: await freshPrefs(), config: noFirebase);
    expect(find.text("Sign-in isn't set up in this build yet."), findsOneWidget);
  });

  testWidgets('Profile shows saved preferences', (tester) async {
    await pumpSpreliaApp(tester, backend: _signedIn(), prefs: await freshPrefs());
    await _tab(tester, 'Profile');
    expect(find.text('Career and interviews'), findsOneWidget);
    expect(find.text('Intermediate (B1)'), findsOneWidget);
    expect(find.text('British English'), findsOneWidget);
    expect(find.text('Bengali'), findsOneWidget);
  });
}
