/// Mirrors the backend's validated post-session analysis JSON.
class Correction {
  const Correction({
    required this.original,
    required this.improved,
    required this.explanation,
    required this.category,
  });

  final String original;
  final String improved;
  final String explanation;
  final String category;

  factory Correction.fromJson(Map<String, dynamic> j) => Correction(
        original: j['original'] as String,
        improved: j['improved'] as String,
        explanation: j['explanation'] as String,
        category: j['category'] as String,
      );
}

class VocabularyItem {
  const VocabularyItem({required this.term, required this.meaning, required this.example});

  final String term;
  final String meaning;
  final String example;

  factory VocabularyItem.fromJson(Map<String, dynamic> j) => VocabularyItem(
        term: j['term'] as String,
        meaning: j['meaning'] as String,
        example: j['example'] as String,
      );
}

class SessionFeedback {
  const SessionFeedback({
    required this.summary,
    required this.strengths,
    required this.corrections,
    required this.vocabulary,
    required this.fluencyObservations,
    required this.recommendedPractice,
  });

  final String summary;
  final List<String> strengths;
  final List<Correction> corrections;
  final List<VocabularyItem> vocabulary;
  final List<String> fluencyObservations;
  final List<String> recommendedPractice;

  static List<String> _strings(dynamic v) => (v as List<dynamic>? ?? []).cast<String>();

  factory SessionFeedback.fromJson(Map<String, dynamic> j) => SessionFeedback(
        summary: j['summary'] as String,
        strengths: _strings(j['strengths']),
        corrections: (j['corrections'] as List<dynamic>? ?? [])
            .map((e) => Correction.fromJson(e as Map<String, dynamic>))
            .toList(),
        vocabulary: (j['vocabulary'] as List<dynamic>? ?? [])
            .map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        fluencyObservations: _strings(j['fluency_observations']),
        recommendedPractice: _strings(j['recommended_practice']),
      );
}
