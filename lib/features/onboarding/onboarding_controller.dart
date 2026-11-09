import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/session/session_controller.dart';
import '../profile/data/profile_models.dart';
import '../profile/data/profile_repository.dart';
import 'onboarding_draft_store.dart';

export 'onboarding_draft_store.dart' show OnboardingStep;

/// Questions in order; [OnboardingStep.plan] is the result screen after saving.
const onboardingQuestions = [
  OnboardingStep.interfaceLanguage,
  OnboardingStep.nativeLanguage,
  OnboardingStep.goals,
  OnboardingStep.level,
  OnboardingStep.dailyGoal,
  OnboardingStep.accent,
];

class OnboardingState {
  const OnboardingState({
    required this.step,
    required this.preferences,
    this.submitting = false,
    this.failure,
    this.plan,
  });

  final OnboardingStep step;
  final LearningPreferences preferences;
  final bool submitting;
  final AppFailure? failure;

  /// Set once onboarding is saved on the server.
  final LearningPlan? plan;

  int get questionIndex => onboardingQuestions.indexOf(step);
  bool get isFirst => questionIndex == 0;

  /// Whether the current question has a valid answer.
  bool get canContinue => switch (step) {
        OnboardingStep.interfaceLanguage => preferences.interfaceLanguage != null,
        OnboardingStep.nativeLanguage => preferences.nativeLanguage != null,
        OnboardingStep.goals => preferences.goals.isNotEmpty,
        OnboardingStep.level => preferences.level != null,
        OnboardingStep.dailyGoal => preferences.dailyGoalMinutes != null,
        OnboardingStep.accent => preferences.accent != null,
        OnboardingStep.plan => true,
      };

  OnboardingState copyWith({
    OnboardingStep? step,
    LearningPreferences? preferences,
    bool? submitting,
    AppFailure? failure,
    bool clearFailure = false,
    LearningPlan? plan,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      preferences: preferences ?? this.preferences,
      submitting: submitting ?? this.submitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      plan: plan ?? this.plan,
    );
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);

class OnboardingController extends Notifier<OnboardingState> {
  late String _uid;

  OnboardingDraftStore get _store => ref.read(onboardingDraftStoreProvider);

  @override
  OnboardingState build() {
    final session = ref.watch(sessionProvider).value;
    if (session is! SignedIn) {
      throw StateError('Onboarding requires a signed-in session');
    }
    _uid = session.user.uid;

    // 1) Resume the on-device draft. 2) Otherwise resume what the server has
    // (e.g. after reinstalling). 3) Otherwise start fresh with English UI.
    final draft = _store.load(_uid);
    if (draft != null) return OnboardingState(step: draft.step, preferences: draft.preferences);

    final server = session.profile.preferences;
    if (server.toJson().isEmpty) {
      // New learner: start at the first question, English preselected.
      return const OnboardingState(
        step: OnboardingStep.interfaceLanguage,
        preferences: LearningPreferences(interfaceLanguage: 'en'),
      );
    }
    return OnboardingState(step: _firstUnanswered(server), preferences: server);
  }

  static OnboardingStep _firstUnanswered(LearningPreferences p) {
    for (final step in onboardingQuestions) {
      if (!OnboardingState(step: step, preferences: p).canContinue) return step;
    }
    return onboardingQuestions.last;
  }

  void _update(OnboardingState next) {
    state = next;
    if (next.step != OnboardingStep.plan) {
      unawaited(_store.save(_uid, OnboardingDraft(step: next.step, preferences: next.preferences)));
    }
  }

  void setInterfaceLanguage(String code) =>
      _update(state.copyWith(preferences: state.preferences.copyWith(interfaceLanguage: code)));

  void setNativeLanguage(String code) =>
      _update(state.copyWith(preferences: state.preferences.copyWith(nativeLanguage: code)));

  void toggleGoal(LearningGoal goal) {
    final goals = {...state.preferences.goals};
    goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
    _update(state.copyWith(preferences: state.preferences.copyWith(goals: goals)));
  }

  void setLevel(EnglishLevel level) => _update(state.copyWith(preferences: state.preferences.copyWith(level: level)));

  void setDailyGoal(int minutes) =>
      _update(state.copyWith(preferences: state.preferences.copyWith(dailyGoalMinutes: minutes)));

  void setAccent(AccentPreference accent) =>
      _update(state.copyWith(preferences: state.preferences.copyWith(accent: accent)));

  void back() {
    if (state.isFirst || state.step == OnboardingStep.plan || state.submitting) return;
    _update(state.copyWith(step: onboardingQuestions[state.questionIndex - 1], clearFailure: true));
  }

  /// Advances to the next question; on the last question saves to the server.
  Future<void> next() async {
    if (!state.canContinue || state.submitting) return;
    if (state.step != onboardingQuestions.last) {
      _update(state.copyWith(step: onboardingQuestions[state.questionIndex + 1], clearFailure: true));
      return;
    }
    state = state.copyWith(submitting: true, clearFailure: true);
    try {
      final (_, plan) = await ref.read(profileRepositoryProvider).saveOnboarding(state.preferences, complete: true);
      state = state.copyWith(
        submitting: false,
        step: OnboardingStep.plan,
        plan: plan ?? const LearningPlan(tutorId: 'emma'),
      );
    } catch (e, st) {
      ref.read(errorReporterProvider).report(e, st, reason: 'Saving onboarding failed');
      state = state.copyWith(submitting: false, failure: AppFailure.from(e));
    }
  }

  /// Leaves onboarding: clears the local draft and reloads the session so the
  /// router moves to Home.
  Future<void> finish() async {
    await _store.clear(_uid);
    await ref.read(sessionProvider.notifier).reload();
  }
}
