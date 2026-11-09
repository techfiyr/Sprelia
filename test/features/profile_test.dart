import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/errors/app_failure.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// Phase 5: profile and settings editing (APP_FLOW §17). Backend calls are faked.
const _user = AuthUser(uid: 'uid-1', email: 'learner@example.com', emailVerified: true, providerIds: ['password']);
const _profile = UserProfile(
  uid: 'uid-1',
  email: 'learner@example.com',
  displayName: 'Rahim',
  timezone: 'UTC',
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

TestBackend _backend() => TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _profile));

Future<void> _openProfile(WidgetTester tester, TestBackend backend) async {
  await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
  await tester.pumpAndSettle();
}

/// Scrolls [finder] to the middle of its list (never under the navigation bar), then taps it.
Future<void> _tapCentered(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapRow(WidgetTester tester, String key) => _tapCentered(tester, find.byKey(ValueKey(key)));

void main() {
  group('Learning preferences', () {
    testWidgets('edit the level: save is enabled only after a change; only that field is sent', (tester) async {
      final backend = _backend();
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-edit-level');

      final save = find.byKey(const ValueKey('preference-save'));
      expect(tester.widget<ButtonStyleButton>(find.descendant(of: save, matching: find.bySubtype<ButtonStyleButton>())).onPressed, isNull);

      await _tapCentered(tester, find.textContaining('(B2)'));
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(backend.profiles.preferenceUpdates, [
        {'level': 'B2'},
      ]);
      expect(find.text('Saved.'), findsOneWidget);
      expect(find.textContaining('(B2)'), findsOneWidget, reason: 'profile shows the new level');
    });

    testWidgets('goals cannot be emptied', (tester) async {
      final backend = _backend();
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-edit-goals');
      await tester.tap(find.text('Career and interviews'));
      await tester.pump();
      final save = find.descendant(of: find.byKey(const ValueKey('preference-save')), matching: find.bySubtype<ButtonStyleButton>());
      expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);
    });

    testWidgets('a server error is shown and nothing is lost', (tester) async {
      final backend = _backend()..profiles.updateError = networkFailure;
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-edit-daily-goal');
      await _tapCentered(tester, find.text('15 minutes a day'));
      await tester.tap(find.byKey(const ValueKey('preference-save')));
      await tester.pumpAndSettle();
      expect(find.text(const NetworkFailure().message), findsOneWidget);
      expect(find.byKey(const ValueKey('preference-save')), findsOneWidget, reason: 'still on the editor');
    });
  });

  group('Account and practice settings', () {
    testWidgets('display name: edit, then clear', (tester) async {
      final backend = _backend();
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-display-name');
      await tester.enterText(find.byKey(const ValueKey('display-name-field')), '  Rahim K ');
      await tester.tap(find.byKey(const ValueKey('display-name-save')));
      await tester.pumpAndSettle();

      await _tapRow(tester, 'profile-display-name');
      await tester.enterText(find.byKey(const ValueKey('display-name-field')), '');
      await tester.tap(find.byKey(const ValueKey('display-name-save')));
      await tester.pumpAndSettle();

      expect(backend.profiles.profileUpdates, [
        {'displayName': 'Rahim K'},
        {'displayName': null},
      ]);
    });

    testWidgets('preferred tutor: choose a tutor, then back to automatic', (tester) async {
      final backend = _backend();
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-preferred-tutor');
      await tester.tap(find.byKey(const ValueKey('tutor-choice-alex')));
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsWidgets);

      await _tapRow(tester, 'profile-preferred-tutor');
      await tester.tap(find.byKey(const ValueKey('tutor-choice-automatic')));
      await tester.pumpAndSettle();
      expect(backend.profiles.profileUpdates, [
        {'preferredTutorId': 'alex'},
        {'preferredTutorId': null},
      ]);
    });

    testWidgets('practice reminders opt-in is saved', (tester) async {
      final backend = _backend();
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-reminders');
      expect(backend.profiles.profileUpdates, [
        {'practiceReminders': true},
      ]);
    });

    testWidgets('time zone can be switched to the device zone', (tester) async {
      final backend = _backend();
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-time-zone');
      await tester.tap(find.byKey(const ValueKey('profile-use-device-time-zone')));
      await tester.pumpAndSettle();
      expect(backend.profiles.profileUpdates, [
        {'timezone': 'Asia/Dhaka'},
      ]);
    });

    testWidgets('a rate-limited time zone change explains itself', (tester) async {
      final backend = _backend()
        ..profiles.updateError = const ServerFailure(
          statusCode: 429,
          code: 'TIMEZONE_CHANGE_TOO_SOON',
          message: 'You can change your time zone once a day. Please try again later.',
        );
      await _openProfile(tester, backend);
      await _tapRow(tester, 'profile-time-zone');
      await tester.tap(find.byKey(const ValueKey('profile-use-device-time-zone')));
      await tester.pumpAndSettle();
      expect(find.text('You can change your time zone once a day. Please try again later.'), findsOneWidget);
    });
  });

  testWidgets('data export copies the JSON document to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final backend = _backend();
    await _openProfile(tester, backend);
    await _tapRow(tester, 'profile-export');
    expect(backend.profiles.exports, 1);
    expect(copied, contains('sprelia-export-v1'));
    expect(find.text('Your data was copied to the clipboard.'), findsOneWidget);
  });
}
