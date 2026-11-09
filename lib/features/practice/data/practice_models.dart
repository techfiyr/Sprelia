/// Practice catalogue from `GET /api/v1/practice/categories` (APP_FLOW §8).
library;

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.minLevel,
    required this.maxLevel,
    required this.objectives,
    required this.estimatedMinutes,
    required this.suggestedTutorId,
    required this.vocabulary,
    this.premium = false,
  });

  final String id;
  final String title;
  final String description;
  final String minLevel;
  final String maxLevel;
  final List<String> objectives;
  final int estimatedMinutes;
  final String suggestedTutorId;
  final List<String> vocabulary;
  final bool premium;

  String get levels => '$minLevel – $maxLevel';

  factory Scenario.fromJson(Map<String, Object?> j) {
    final cefr = (j['cefr']! as Map).cast<String, Object?>();
    return Scenario(
      id: j['id']! as String,
      title: j['title']! as String,
      description: (j['description'] as String?) ?? '',
      minLevel: cefr['min']! as String,
      maxLevel: cefr['max']! as String,
      objectives: (j['objectives'] as List?)?.cast<String>() ?? const [],
      estimatedMinutes: (j['estimatedMinutes'] as int?) ?? 5,
      suggestedTutorId: j['suggestedTutorId']! as String,
      vocabulary: (j['vocabulary'] as List?)?.cast<String>() ?? const [],
      premium: j['premium'] == true,
    );
  }
}

class PracticeCategory {
  const PracticeCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.scenarios,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final List<Scenario> scenarios;

  factory PracticeCategory.fromJson(Map<String, Object?> j) => PracticeCategory(
        id: j['id']! as String,
        title: j['title']! as String,
        description: (j['description'] as String?) ?? '',
        icon: (j['icon'] as String?) ?? 'everyday',
        scenarios: ((j['scenarios'] as List?) ?? const [])
            .map((e) => Scenario.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
      );
}
