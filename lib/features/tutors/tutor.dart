/// Brand tone used for a tutor's placeholder avatar. Resolved to theme colors
/// in `TutorAvatar`; models never hold raw colors.
enum TutorTone {
  primary,
  primaryDark,
  accent;

  static TutorTone fromWire(Object? v) => switch (v) {
        'primaryDark' => TutorTone.primaryDark,
        'accent' => TutorTone.accent,
        _ => TutorTone.primary,
      };
}

/// Public tutor metadata from `GET /api/v1/tutors` (APP_FLOW §7). Prompts and
/// voice configuration live only on the backend and are never sent to the app.
class Tutor {
  const Tutor({
    required this.id,
    required this.name,
    required this.title,
    required this.personality,
    required this.description,
    required this.minLevel,
    required this.maxLevel,
    required this.categoryIds,
    required this.tone,
    this.voiceAvailable = false,
  });

  final String id;
  final String name;
  final String title;
  final List<String> personality;
  final String description;
  final String minLevel;
  final String maxLevel;
  final List<String> categoryIds;
  final TutorTone tone;

  /// Voice conversations exist for this tutor (prototype: Emma only).
  final bool voiceAvailable;

  String get levels => '$minLevel – $maxLevel';

  factory Tutor.fromJson(Map<String, Object?> j) {
    final levels = (j['levels']! as Map).cast<String, Object?>();
    return Tutor(
      id: j['id']! as String,
      name: j['name']! as String,
      title: j['title']! as String,
      personality: (j['personality'] as List?)?.cast<String>() ?? const [],
      description: (j['description'] as String?) ?? '',
      minLevel: levels['min']! as String,
      maxLevel: levels['max']! as String,
      categoryIds: (j['categoryIds'] as List?)?.cast<String>() ?? const [],
      tone: TutorTone.fromWire(j['tone']),
      voiceAvailable: j['voiceAvailable'] == true,
    );
  }

  /// Shown while the catalogue loads or if a tutor id is unknown.
  factory Tutor.placeholder(String id) => Tutor(
        id: id,
        name: id.isEmpty ? 'Tutor' : '${id[0].toUpperCase()}${id.substring(1)}',
        title: '',
        personality: const [],
        description: '',
        minLevel: 'A1',
        maxLevel: 'B2',
        categoryIds: const [],
        tone: TutorTone.primary,
      );
}
