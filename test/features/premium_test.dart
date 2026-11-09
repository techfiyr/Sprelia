import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/routing/app_router.dart';
import 'package:speakdaily/core/services/realtime/audio_io.dart';
import 'package:speakdaily/core/services/realtime/realtime_provider.dart';
import 'package:speakdaily/features/practice/conversation_controller.dart';
import 'package:speakdaily/features/practice/data/conversation_repository.dart';
import 'package:speakdaily/features/premium/premium_services.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';
import 'package:speakdaily/features/tutors/tutor.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// Phase 9: server-verified Premium, paywall entry points and the ad placement policy.
const _user = AuthUser(uid: 'uid-1', email: 'learner@example.com', emailVerified: true, providerIds: ['password']);
const _profile = UserProfile(uid: 'uid-1', timezone: 'UTC', onboardingStatus: OnboardingStatus.completed);

Dashboard _dashboard({bool premium = false}) => Dashboard(
      displayName: null,
      dailyGoalMinutes: 10,
      todaySpeakingSeconds: 0,
      freeAllowanceSeconds: premium ? 1800 : 600,
      remainingFreeSeconds: premium ? 1800 : 600,
      streakDays: 0,
      weeklySpeakingSeconds: 0,
      weeklySessions: 0,
      recommendation: const LearningPlan(tutorId: 'alex', scenarioId: 'presentations', categoryIds: ['professional']),
      isPremium: premium,
    );

/// Alex with a voice (the shared fake keeps him voice-less for the "coming soon" test).
const _voiceAlex = Tutor(
  id: 'alex',
  name: 'Alex',
  title: 'Professional Communication Coach',
  personality: ['Professional'],
  description: 'Interviews and meetings.',
  minLevel: 'A2',
  maxLevel: 'C1',
  categoryIds: ['professional'],
  tone: TutorTone.primaryDark,
  voiceAvailable: true,
);

TestBackend _backend({bool premium = false}) {
  final backend = TestBackend(
    auth: FakeAuthRepository(signedIn: _user),
    profiles: FakeProfileRepository(profile: _profile)..dashboard = _dashboard(premium: premium),
  );
  backend.catalog.tutorList = [FakeCatalogRepository.tutors.first, _voiceAlex];
  return backend;
}

class _Mic implements AudioInput {
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Future<Stream<Uint8List>> start({required int sampleRate}) async => const Stream.empty();
  @override
  Future<void> stop() async {}
}

class _LimitReached implements ConversationRepository {
  @override
  Future<RealtimeSessionGrant> start({required String tutorId, String? scenarioId}) async => throw const ConversationStartFailure(
        ConversationStartError.dailyLimitReached,
        "You've used today's free speaking time. It resets at midnight.",
      );
  @override
  Future<int?> end(String id, ConversationEndReason reason, {List<Map<String, Object?>> transcript = const []}) async => null;
}

FilledButton _start(WidgetTester tester) =>
    tester.widget<FilledButton>(find.descendant(of: find.byKey(const ValueKey('prepare-start')), matching: find.byType(FilledButton)));

void main() {
  test('ad policy: non-subscribers only, never in a conversation', () {
    for (final p in AdPlacement.values) {
      expect(adAllowed(Plan.premium, p), isFalse, reason: 'premium $p');
    }
    expect(adAllowed(Plan.free, AdPlacement.homeBanner), isTrue);
    expect(adAllowed(Plan.free, AdPlacement.afterFeedback), isTrue);
    expect(adAllowed(Plan.free, AdPlacement.conversation), isFalse);
    expect(adAllowed(Plan.free, AdPlacement.paywall), isTrue);
    expect(adAllowed(Plan.free, AdPlacement.bottomBanner), isTrue);
    expect(const UnavailableAdService().available, isFalse, reason: 'no ads are loaded until AdMob is configured');
  });

  testWidgets('a Premium scenario is locked on the free plan and leads to the paywall', (tester) async {
    await pumpSpreliaApp(tester, backend: _backend(), prefs: await freshPrefs());
    await tester.tap(find.byKey(const ValueKey('home-start-speaking')));
    await tester.pumpAndSettle();
    expect(_start(tester).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('prepare-see-premium')));
    await tester.pumpAndSettle();
    expect(find.text('Hermione Premium'), findsOneWidget);
    expect(find.textContaining('Test prices, not final'), findsOneWidget);
    expect(find.text('Premium purchases are not available yet.'), findsOneWidget);
    final subscribe = find.descendant(of: find.byKey(const ValueKey('paywall-subscribe')), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(subscribe).onPressed, isNull);
  });

  testWidgets('with a server-verified Premium plan the scenario can start', (tester) async {
    await pumpSpreliaApp(tester, backend: _backend(premium: true), prefs: await freshPrefs());
    await tester.tap(find.byKey(const ValueKey('home-start-speaking')));
    await tester.pumpAndSettle();
    expect(_start(tester).onPressed, isNotNull);
    expect(find.byKey(const ValueKey('prepare-see-premium')), findsNothing);
  });

  testWidgets('reaching the daily limit offers Premium instead of "Try again"', (tester) async {
    await pumpSpreliaApp(
      tester,
      backend: _backend(),
      prefs: await freshPrefs(),
      extraOverrides: [
        conversationRepositoryProvider.overrideWithValue(_LimitReached()),
        audioInputFactory.overrideWithValue(_Mic.new),
      ],
    );
    unawaited(GoRouter.of(tester.element(find.byType(NavigationBar))).push(AppRoutes.conversation('emma')));
    await tester.pumpAndSettle();
    expect(find.textContaining("You've used today's free speaking time"), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('conversation-see-premium')));
    await tester.pumpAndSettle();
    expect(find.text('Hermione Premium'), findsOneWidget);
  });

  testWidgets('profile shows the server plan', (tester) async {
    final backend = _backend()..subscription.info = const SubscriptionInfo(plan: Plan.premium, dailyAllowanceSeconds: 1800);
    await pumpSpreliaApp(tester, backend: backend, prefs: await freshPrefs());
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('profile-subscription')), 200);
    expect(find.descendant(of: find.byKey(const ValueKey('profile-subscription')), matching: find.text('Premium')), findsOneWidget);
  });
}
