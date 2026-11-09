/// Learning preferences collected during onboarding (APP_FLOW §5).
/// Wire values match the backend schema (`backend/src/modules/users/user.schemas.ts`).
library;

enum LearningGoal {
  everyday('everyday'),
  career('career'),
  business('business'),
  travelSocial('travel_social'),
  academic('academic'),
  confidence('confidence');

  const LearningGoal(this.wire);
  final String wire;

  static LearningGoal? fromWire(Object? v) => values.where((e) => e.wire == v).firstOrNull;
}

/// Self-reported level. Not a formal CEFR assessment (APP_FLOW §5).
enum EnglishLevel {
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c1('C1'),
  notSure('not_sure');

  const EnglishLevel(this.wire);
  final String wire;

  static EnglishLevel? fromWire(Object? v) => values.where((e) => e.wire == v).firstOrNull;
}

enum AccentPreference {
  american('american'),
  british('british'),
  australian('australian'),
  international('international');

  const AccentPreference(this.wire);
  final String wire;

  static AccentPreference? fromWire(Object? v) => values.where((e) => e.wire == v).firstOrNull;
}

/// Allowed daily speaking targets in minutes (motivational, not the allowance).
/// Owner decision 2026-11-09: 5, 10 and 15 minutes.
const dailyGoalOptions = [5, 10, 15];

/// Immutable, possibly partial set of preferences.
class LearningPreferences {
  const LearningPreferences({
    this.interfaceLanguage,
    this.nativeLanguage,
    this.goals = const {},
    this.level,
    this.dailyGoalMinutes,
    this.accent,
  });

  final String? interfaceLanguage;
  final String? nativeLanguage;
  final Set<LearningGoal> goals;
  final EnglishLevel? level;
  final int? dailyGoalMinutes;
  final AccentPreference? accent;

  bool get isComplete =>
      interfaceLanguage != null &&
      nativeLanguage != null &&
      goals.isNotEmpty &&
      level != null &&
      dailyGoalMinutes != null &&
      accent != null;

  LearningPreferences copyWith({
    String? interfaceLanguage,
    String? nativeLanguage,
    Set<LearningGoal>? goals,
    EnglishLevel? level,
    int? dailyGoalMinutes,
    AccentPreference? accent,
  }) {
    return LearningPreferences(
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      goals: goals ?? this.goals,
      level: level ?? this.level,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      accent: accent ?? this.accent,
    );
  }

  /// Only set fields are serialized (partial saves).
  Map<String, Object?> toJson() => {
        if (interfaceLanguage != null) 'interfaceLanguage': interfaceLanguage,
        if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
        if (goals.isNotEmpty) 'goals': LearningGoal.values.where(goals.contains).map((g) => g.wire).toList(),
        if (level != null) 'level': level!.wire,
        if (dailyGoalMinutes != null) 'dailyGoalMinutes': dailyGoalMinutes,
        if (accent != null) 'accent': accent!.wire,
      };

  /// Tolerant parsing: unknown or invalid values are dropped, never thrown.
  factory LearningPreferences.fromJson(Map<String, Object?> j) {
    final goals = j['goals'];
    final minutes = j['dailyGoalMinutes'];
    return LearningPreferences(
      interfaceLanguage: j['interfaceLanguage'] is String ? j['interfaceLanguage'] as String : null,
      nativeLanguage: j['nativeLanguage'] is String ? j['nativeLanguage'] as String : null,
      goals: goals is List ? goals.map(LearningGoal.fromWire).whereType<LearningGoal>().toSet() : const {},
      level: EnglishLevel.fromWire(j['level']),
      dailyGoalMinutes: minutes is int && dailyGoalOptions.contains(minutes) ? minutes : null,
      accent: AccentPreference.fromWire(j['accent']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LearningPreferences &&
      other.interfaceLanguage == interfaceLanguage &&
      other.nativeLanguage == nativeLanguage &&
      other.goals.length == goals.length &&
      other.goals.containsAll(goals) &&
      other.level == level &&
      other.dailyGoalMinutes == dailyGoalMinutes &&
      other.accent == accent;

  @override
  int get hashCode =>
      Object.hash(interfaceLanguage, nativeLanguage, Object.hashAllUnordered(goals), level, dailyGoalMinutes, accent);
}
