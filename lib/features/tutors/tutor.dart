/// Brand tone used for a tutor's placeholder avatar. Resolved to theme colors
/// in `TutorAvatar`; models never hold raw colors.
enum TutorTone { primary, primaryDark, accent }

/// Client-side tutor metadata for display (APP_FLOW §7). Prompts and voice configuration
/// live on the backend (`backend/src/tutors.ts`) and are never sent to the app.
class Tutor {
  const Tutor({
    required this.id,
    required this.name,
    required this.title,
    required this.personality,
    required this.levels,
    required this.focus,
    required this.tone,
    this.available = true,
  });

  final String id;
  final String name;
  final String title;
  final String personality;
  final String levels;
  final String focus;
  final TutorTone tone;

  /// Prototype phase: only Emma is enabled.
  final bool available;
}

const tutors = <Tutor>[
  Tutor(
    id: 'emma',
    name: 'Emma',
    title: 'Friendly English Coach',
    personality: 'Patient and encouraging',
    levels: 'A1 – B1',
    focus: 'Everyday communication',
    tone: TutorTone.primary,
  ),
  Tutor(
    id: 'alex',
    name: 'Alex',
    title: 'Professional Communication Coach',
    personality: 'Professional, structured and helpful',
    levels: 'A2 – C1',
    focus: 'Interviews, meetings, presentations',
    tone: TutorTone.primaryDark,
    available: false,
  ),
  Tutor(
    id: 'sofia',
    name: 'Sofia',
    title: 'Everyday Conversation Partner',
    personality: 'Natural, expressive and friendly',
    levels: 'A1 – B2',
    focus: 'Everyday, social and travel situations',
    tone: TutorTone.accent,
    available: false,
  ),
];

Tutor tutorById(String id) => tutors.firstWhere((t) => t.id == id, orElse: () => tutors.first);
