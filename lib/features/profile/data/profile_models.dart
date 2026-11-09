import 'learning_preferences.dart';

export 'learning_preferences.dart';

enum OnboardingStatus { notStarted, inProgress, completed }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.timezone,
    required this.onboardingStatus,
    this.email,
    this.displayName,
    this.preferences = const LearningPreferences(),
    this.preferredTutorId,
    this.practiceReminders = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String timezone;
  final OnboardingStatus onboardingStatus;
  final LearningPreferences preferences;

  /// The learner's explicit tutor choice; null means "choose for me".
  final String? preferredTutorId;

  /// Opt-in for practice reminders (delivery arrives with push notifications).
  final bool practiceReminders;

  bool get onboardingCompleted => onboardingStatus == OnboardingStatus.completed;

  factory UserProfile.fromJson(Map<String, Object?> j) {
    final onboarding = (j['onboarding'] as Map?)?.cast<String, Object?>() ?? const {};
    return UserProfile(
      uid: j['uid']! as String,
      email: j['email'] as String?,
      displayName: j['displayName'] as String?,
      timezone: (j['timezone'] as String?) ?? 'UTC',
      onboardingStatus: switch (onboarding['status']) {
        'completed' => OnboardingStatus.completed,
        'in_progress' => OnboardingStatus.inProgress,
        _ => OnboardingStatus.notStarted,
      },
      preferences: LearningPreferences.fromJson((onboarding['preferences'] as Map?)?.cast<String, Object?>() ?? const {}),
      preferredTutorId: j['preferredTutorId'] as String?,
      practiceReminders: j['practiceReminders'] == true,
    );
  }
}

/// Server-generated starting recommendation.
class LearningPlan {
  const LearningPlan({required this.tutorId, this.scenarioId, this.categoryIds = const []});

  final String tutorId;
  final String? scenarioId;
  final List<String> categoryIds;

  factory LearningPlan.fromJson(Map<String, Object?> j) => LearningPlan(
        tutorId: j['tutorId']! as String,
        scenarioId: j['scenarioId'] as String?,
        categoryIds: (j['categoryIds'] as List?)?.cast<String>() ?? const [],
      );
}

/// Home dashboard, built by the server from recorded data only.
class Dashboard {
  const Dashboard({
    required this.displayName,
    required this.dailyGoalMinutes,
    required this.todaySpeakingSeconds,
    required this.freeAllowanceSeconds,
    required this.remainingFreeSeconds,
    required this.streakDays,
    required this.weeklySpeakingSeconds,
    required this.weeklySessions,
    required this.recommendation,
    this.isPremium = false,
  });

  final String? displayName;

  /// Server-verified plan (the app never decides entitlement).
  final bool isPremium;
  final int? dailyGoalMinutes;
  final int todaySpeakingSeconds;
  final int freeAllowanceSeconds;
  final int remainingFreeSeconds;
  final int streakDays;
  final int weeklySpeakingSeconds;
  final int weeklySessions;
  final LearningPlan recommendation;

  factory Dashboard.fromJson(Map<String, Object?> j) {
    final today = (j['today']! as Map).cast<String, Object?>();
    final progress = (j['progress']! as Map).cast<String, Object?>();
    return Dashboard(
      displayName: j['displayName'] as String?,
      dailyGoalMinutes: j['dailyGoalMinutes'] as int?,
      todaySpeakingSeconds: today['speakingSeconds']! as int,
      freeAllowanceSeconds: today['freeAllowanceSeconds']! as int,
      remainingFreeSeconds: today['remainingFreeSeconds']! as int,
      streakDays: progress['streakDays']! as int,
      weeklySpeakingSeconds: progress['weeklySpeakingSeconds']! as int,
      weeklySessions: progress['weeklySessions']! as int,
      recommendation: LearningPlan.fromJson((j['recommendation']! as Map).cast<String, Object?>()),
      isPremium: j['plan'] == 'premium',
    );
  }
}
