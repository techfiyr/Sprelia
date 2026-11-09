import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/features/practice/data/practice_models.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';
import 'package:speakdaily/features/tutors/tutor.dart';

void main() {
  test('Tutor.fromJson reads the public catalogue shape', () {
    final t = Tutor.fromJson({
      'id': 'alex',
      'name': 'Alex',
      'title': 'Professional Communication Coach',
      'personality': ['Professional'],
      'description': 'Interviews.',
      'levels': {'min': 'A2', 'max': 'C1'},
      'categoryIds': ['professional'],
      'tone': 'primaryDark',
      'voiceAvailable': false,
      'voiceSampleAvailable': false,
    });
    expect(t.levels, 'A2 – C1');
    expect(t.tone, TutorTone.primaryDark);
    expect(t.voiceAvailable, isFalse);
  });

  test('Tutor.placeholder is used for unknown ids', () {
    expect(Tutor.placeholder('sofia').name, 'Sofia');
  });

  test('Scenario.fromJson', () {
    final s = Scenario.fromJson({
      'id': 'airport',
      'title': 'At the airport',
      'description': 'Check in.',
      'cefr': {'min': 'A1', 'max': 'B1'},
      'objectives': ['Check in'],
      'estimatedMinutes': 5,
      'suggestedTutorId': 'emma',
      'vocabulary': ['gate'],
      'premium': false,
    });
    expect(s.levels, 'A1 – B1');
    expect(s.suggestedTutorId, 'emma');
  });

  group('LearningPreferences', () {
    const full = LearningPreferences(
      interfaceLanguage: 'en',
      nativeLanguage: 'bn',
      goals: {LearningGoal.career, LearningGoal.travelSocial},
      level: EnglishLevel.notSure,
      dailyGoalMinutes: 15,
      accent: AccentPreference.british,
    );

    test('serializes to backend wire values and round-trips', () {
      final json = full.toJson();
      expect(json, {
        'interfaceLanguage': 'en',
        'nativeLanguage': 'bn',
        'goals': ['career', 'travel_social'],
        'level': 'not_sure',
        'dailyGoalMinutes': 15,
        'accent': 'british',
      });
      expect(LearningPreferences.fromJson(json), full);
      expect(full.isComplete, isTrue);
    });

    test('partial preferences only serialize set fields', () {
      expect(const LearningPreferences(level: EnglishLevel.a2).toJson(), {'level': 'A2'});
    });

    test('drops unknown or invalid stored values instead of throwing', () {
      final p = LearningPreferences.fromJson({'goals': ['career', 'get_rich'], 'level': 'C2', 'dailyGoalMinutes': 7});
      expect(p.goals, {LearningGoal.career});
      expect(p.level, isNull);
      expect(p.dailyGoalMinutes, isNull);
    });
  });

  test('UserProfile and Dashboard parse API responses', () {
    final profile = UserProfile.fromJson({
      'uid': 'u1',
      'email': 'a@example.com',
      'displayName': null,
      'timezone': 'Asia/Dhaka',
      'onboarding': {'status': 'completed', 'completedAt': '2026-11-09T00:00:00Z', 'preferences': {'level': 'B1'}},
    });
    expect(profile.onboardingCompleted, isTrue);
    expect(profile.preferences.level, EnglishLevel.b1);

    final d = Dashboard.fromJson({
      'displayName': 'A',
      'plan': 'free',
      'dailyGoalMinutes': null,
      'today': {'date': '2026-11-09', 'timezone': 'UTC', 'speakingSeconds': 0, 'freeAllowanceSeconds': 600, 'remainingFreeSeconds': 600},
      'progress': {'streakDays': 0, 'weeklySpeakingSeconds': 0, 'weeklySessions': 0},
      'recommendation': {'tutorId': 'emma', 'scenarioId': null, 'categoryIds': ['everyday']},
    });
    expect(d.remainingFreeSeconds, 600);
    expect(d.recommendation.scenarioId, isNull);
  });
}
