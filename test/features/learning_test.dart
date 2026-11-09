import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/routing/app_router.dart';
import 'package:speakdaily/features/learn/data/learning_repository.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// Phase 8: post-session feedback, Mistake Vault, Vocabulary and Progress (fakes only).
const _user = AuthUser(uid: 'uid-1', email: 'learner@example.com', emailVerified: true, providerIds: ['password']);
const _profile = UserProfile(
  uid: 'uid-1',
  email: 'learner@example.com',
  timezone: 'UTC',
  onboardingStatus: OnboardingStatus.completed,
);

TestBackend _backend() => TestBackend(auth: FakeAuthRepository(signedIn: _user), profiles: FakeProfileRepository(profile: _profile));

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> _openFeedback(WidgetTester tester, TestBackend backend) async {
  await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
  unawaited(GoRouter.of(tester.element(find.byType(NavigationBar))).push(AppRoutes.feedback('0b9b6f0c-1111-4222-8333-944455556666')));
  await tester.pumpAndSettle();
}

void main() {
  group('Feedback screen', () {
    testWidgets('shows validated corrections, vocabulary and next steps', (tester) async {
      final backend = _backend();
      await _openFeedback(tester, backend);
      expect(find.text('You checked in for your flight.'), findsOneWidget);
      expect(find.text('I go yesterday'), findsOneWidget);
      expect(find.text('I went yesterday'), findsOneWidget);
      expect(find.text('boarding pass'), findsOneWidget);
    });

    testWidgets('polls while analysis is pending', (tester) async {
      final backend = _backend()
        ..learning.feedbackSequence = [const FeedbackPending(), const FeedbackPending(), ..._backend().learning.feedbackSequence];
      await _openFeedback(tester, backend);
      expect(backend.learning.feedbackCalls, 3);
      expect(find.text('I went yesterday'), findsOneWidget);
    });

    testWidgets('too little speech explains itself', (tester) async {
      final backend = _backend()..learning.feedbackSequence = [const FeedbackInsufficientSpeech()];
      await _openFeedback(tester, backend);
      expect(find.textContaining('too short for feedback'), findsOneWidget);
    });

    testWidgets('a failure offers a retry that works', (tester) async {
      final ok = _backend().learning.feedbackSequence.single;
      final backend = _backend()..learning.feedbackSequence = [const FeedbackFailed("Feedback isn't available right now."), ok];
      await _openFeedback(tester, backend);
      expect(find.text("Feedback isn't available right now."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('I went yesterday'), findsOneWidget);
    });
  });

  group('Learn tab', () {
    testWidgets('Mistake Vault: mark a correction as mastered', (tester) async {
      final backend = _backend();
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _tab(tester, 'Learn');
      expect(find.text('I went yesterday'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mistake-mastered-m1')));
      await tester.pumpAndSettle();
      expect(backend.learning.masteredCalls, [('m1', true)]);
      expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('mistake-mastered-m1'))).value, isTrue);
    });

    testWidgets('Vocabulary: mark a word as learned', (tester) async {
      final backend = _backend();
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _tab(tester, 'Learn');
      await tester.tap(find.text('Vocabulary'));
      await tester.pumpAndSettle();
      expect(find.text('Your ticket to board.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('vocabulary-learned-boarding-pass')));
      await tester.pumpAndSettle();
      expect(backend.learning.learnedCalls, [('boarding-pass', true)]);
    });

    testWidgets('empty states', (tester) async {
      final backend = _backend()
        ..learning.mistakes = []
        ..learning.vocabulary = [];
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _tab(tester, 'Learn');
      expect(find.textContaining('No saved corrections yet'), findsOneWidget);
      await tester.tap(find.text('Vocabulary'));
      await tester.pumpAndSettle();
      expect(find.textContaining("haven't saved any vocabulary"), findsOneWidget);
    });
  });

  group('Progress tab', () {
    testWidgets('shows server statistics, a labelled week chart and recent sessions', (tester) async {
      await pumpSpreliaApp(tester, backend: _backend(), prefs: await freshPrefs());
      await _tab(tester, 'Progress');
      expect(find.text('1-day streak'), findsOneWidget);
      expect(find.text('5 min spoken in the last 30 days'), findsOneWidget);
      expect(find.text('Corrections to review: 1 · mastered: 0'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r': 5 min$')), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('recent-s1')), 200);
      expect(find.text('Emma'), findsWidgets);
    });

    testWidgets('empty state before the first conversation', (tester) async {
      final backend = _backend();
      backend.learning.progress = const Progress(
        days: [],
        totalSpeakingSeconds: 0,
        totalSessions: 0,
        streakDays: 0,
        mistakesOpen: 0,
        mistakesMastered: 0,
        vocabularyTotal: 0,
        vocabularyLearned: 0,
        recentSessions: [],
      );
      await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
      await _tab(tester, 'Progress');
      expect(find.text('No progress yet'), findsOneWidget);
    });
  });
}
