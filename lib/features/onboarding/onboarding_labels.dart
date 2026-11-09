import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../profile/data/learning_preferences.dart';
import 'languages.dart';

/// Localized labels for preference values, shared by onboarding and profile.
extension PreferenceLabels on BuildContext {
  String goalLabel(LearningGoal g) => switch (g) {
        LearningGoal.everyday => l10n.goalEveryday,
        LearningGoal.career => l10n.goalCareer,
        LearningGoal.business => l10n.goalBusiness,
        LearningGoal.travelSocial => l10n.goalTravelSocial,
        LearningGoal.academic => l10n.goalAcademic,
        LearningGoal.confidence => l10n.goalConfidence,
      };

  String goalDescription(LearningGoal g) => switch (g) {
        LearningGoal.everyday => l10n.goalEverydayDescription,
        LearningGoal.career => l10n.goalCareerDescription,
        LearningGoal.business => l10n.goalBusinessDescription,
        LearningGoal.travelSocial => l10n.goalTravelSocialDescription,
        LearningGoal.academic => l10n.goalAcademicDescription,
        LearningGoal.confidence => l10n.goalConfidenceDescription,
      };

  /// e.g. "Elementary (A2)". "Not sure" never shows a CEFR code.
  String levelLabel(EnglishLevel l) => switch (l) {
        EnglishLevel.a1 => '${l10n.levelA1} (A1)',
        EnglishLevel.a2 => '${l10n.levelA2} (A2)',
        EnglishLevel.b1 => '${l10n.levelB1} (B1)',
        EnglishLevel.b2 => '${l10n.levelB2} (B2)',
        EnglishLevel.c1 => '${l10n.levelC1} (C1)',
        EnglishLevel.notSure => l10n.levelNotSure,
      };

  String levelDescription(EnglishLevel l) => switch (l) {
        EnglishLevel.a1 => l10n.levelA1Description,
        EnglishLevel.a2 => l10n.levelA2Description,
        EnglishLevel.b1 => l10n.levelB1Description,
        EnglishLevel.b2 => l10n.levelB2Description,
        EnglishLevel.c1 => l10n.levelC1Description,
        EnglishLevel.notSure => l10n.levelNotSureDescription,
      };

  String accentLabel(AccentPreference a) => switch (a) {
        AccentPreference.american => l10n.accentAmerican,
        AccentPreference.british => l10n.accentBritish,
        AccentPreference.australian => l10n.accentAustralian,
        AccentPreference.international => l10n.accentInternational,
      };

  String dailyGoalHint(int minutes) => switch (minutes) {
        5 => l10n.dailyGoal5,
        10 => l10n.dailyGoal10,
        _ => l10n.dailyGoal15,
      };

  String languageName(String? code) {
    if (code == null) return '';
    final match = nativeLanguages.where((l) => l.code == code).firstOrNull;
    return match == null ? code : match.englishName;
  }
}

IconData categoryIcon(String key) => switch (key) {
      'professional' => Icons.work_outline_rounded,
      'academic' => Icons.school_outlined,
      'travel' => Icons.flight_takeoff_rounded,
      'social' => Icons.groups_outlined,
      _ => Icons.forum_outlined,
    };
