import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/features/onboarding/onboarding_draft_store.dart';
import 'package:speakdaily/features/onboarding/onboarding_screen.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _user = AuthUser(uid: 'uid-1', email: 'learner@example.com');
const _fresh = UserProfile(uid: 'uid-1', timezone: 'Asia/Dhaka', onboardingStatus: OnboardingStatus.notStarted);

TestBackend _backend() =>
    TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _fresh));

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _pickLanguage(WidgetTester tester, String query, String label) async {
  await tester.enterText(find.byKey(const ValueKey('native-language-search')), query);
  await tester.pumpAndSettle();
  await _tapText(tester, label);
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('completes all steps, saves to the server and shows the plan', (tester) async {
    final backend = _backend();
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Step 1 of 6'), findsOneWidget);

    // 1. Interface language: English preselected.
    await _continue(tester);
    // 2. Native language with search.
    expect(find.text("What's your first language?"), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull, reason: 'needs an answer');
    await tester.enterText(find.byKey(const ValueKey('native-language-search')), 'beng');
    await tester.pumpAndSettle();
    await _tapText(tester, 'বাংলা');
    await _continue(tester);
    // 3. Goals (multi-select).
    await _tapText(tester, 'Career and interviews');
    await _tapText(tester, 'Speaking confidence');
    await _continue(tester);
    // 4. Level (A1–C1 + not sure).
    expect(find.textContaining('not a test'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Advanced (C1)'), 200);
    expect(find.text('Advanced (C1)'), findsOneWidget);
    await _tapText(tester, 'Intermediate (B1)');
    await _continue(tester);
    // 5. Daily target: 5, 10 or 15 minutes only.
    expect(find.text('20 minutes a day'), findsNothing);
    expect(find.text('15 minutes a day'), findsOneWidget);
    await _tapText(tester, '10 minutes a day');
    await _continue(tester);
    // 6. Accent → save.
    await _tapText(tester, 'International / no preference');
    expect(find.text('Create my plan'), findsOneWidget);
    await _continue(tester);

    final (prefs, complete) = backend.profiles.saveCalls.single;
    expect(complete, isTrue);
    expect(prefs.toJson(), {
      'interfaceLanguage': 'en',
      'nativeLanguage': 'bn',
      'goals': ['career', 'confidence'],
      'level': 'B1',
      'dailyGoalMinutes': 10,
      'accent': 'international',
    });

    expect(find.text('Your learning plan is ready'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Professional'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan-start')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'lands on Home');
  });

  testWidgets('Back keeps earlier answers', (tester) async {
    await pumpSpreliaApp(tester, backend: _backend(), prefs: await freshPrefs());
    await _continue(tester);
    await _pickLanguage(tester, 'span', 'Español');
    await _continue(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text("What's your first language?"), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('progress survives an app restart', (tester) async {
    final backend = _backend();
    final prefs = await freshPrefs();
    await pumpSpreliaApp(tester, backend: backend, prefs: prefs);
    await _continue(tester);
    await _pickLanguage(tester, 'span', 'Español');
    await _continue(tester);
    await _tapText(tester, 'Travel and social life');
    await _continue(tester);
    expect(find.text('Step 4 of 6'), findsOneWidget);

    // Simulate the app being closed and reopened (fresh providers, same device storage).
    await pumpSpreliaApp(tester, backend: backend, prefs: prefs);

    expect(find.text('Step 4 of 6'), findsOneWidget);
    final draft = OnboardingDraftStore(prefs).load('uid-1')!;
    expect(draft.step, OnboardingStep.level);
    expect(draft.preferences.nativeLanguage, 'es');
    expect(draft.preferences.goals, {LearningGoal.travelSocial});
    expect(backend.profiles.saveCalls, isEmpty, reason: 'nothing is sent until the learner finishes');
  });

  testWidgets('drafts are per user', (tester) async {
    final prefs = await freshPrefs();
    await OnboardingDraftStore(prefs).save(
      'someone-else',
      const OnboardingDraft(step: OnboardingStep.accent, preferences: LearningPreferences(nativeLanguage: 'fr')),
    );
    await pumpSpreliaApp(tester, backend: _backend(), prefs: prefs);
    expect(find.text('Step 1 of 6'), findsOneWidget);
  });

  testWidgets('resumes from server-side preferences when there is no local draft', (tester) async {
    final backend = TestBackend(
      auth: FakeAuthRepository(signedIn: _user),
      profiles: FakeProfileRepository(
        profile: const UserProfile(
          uid: 'uid-1',
          timezone: 'UTC',
          onboardingStatus: OnboardingStatus.inProgress,
          preferences: LearningPreferences(interfaceLanguage: 'en', nativeLanguage: 'de', goals: {LearningGoal.academic}),
        ),
      ),
    );
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    expect(find.text('Step 4 of 6'), findsOneWidget);
  });

  testWidgets('a corrupt draft is ignored rather than crashing', (tester) async {
    await pumpSpreliaApp(
      tester,
      backend: _backend(),
      prefs: await freshPrefs({'onboarding_draft_v1_uid-1': '{not json'}),
    );
    expect(find.text('Step 1 of 6'), findsOneWidget);
  });

  testWidgets('a failed save shows a friendly error and keeps the answers', (tester) async {
    final backend = _backend()..profiles.saveError = networkFailure;
    final prefs = await freshPrefs();
    await OnboardingDraftStore(prefs).save(
      'uid-1',
      const OnboardingDraft(
        step: OnboardingStep.accent,
        preferences: LearningPreferences(
          interfaceLanguage: 'en',
          nativeLanguage: 'bn',
          goals: {LearningGoal.everyday},
          level: EnglishLevel.a2,
          dailyGoalMinutes: 5,
        ),
      ),
    );
    await pumpSpreliaApp(tester, backend: backend, prefs: prefs);
    await _tapText(tester, 'American English');
    await _continue(tester);

    expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
    expect(find.text('Step 6 of 6'), findsOneWidget);

    backend.profiles.saveError = null;
    await _continue(tester);
    expect(find.text('Your learning plan is ready'), findsOneWidget);
  });
}
