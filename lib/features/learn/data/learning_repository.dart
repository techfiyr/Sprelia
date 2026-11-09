import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/api_client.dart';
import '../../feedback/session_feedback.dart';

/// Post-session feedback status (server contract: pending → completed / insufficient_speech /
/// failed). `failed` is retryable.
sealed class FeedbackResult {
  const FeedbackResult();
}

final class FeedbackPending extends FeedbackResult {
  const FeedbackPending();
}

final class FeedbackCompleted extends FeedbackResult {
  const FeedbackCompleted(this.feedback);
  final SessionFeedback feedback;
}

final class FeedbackInsufficientSpeech extends FeedbackResult {
  const FeedbackInsufficientSpeech();
}

final class FeedbackFailed extends FeedbackResult {
  const FeedbackFailed(this.message);
  final String message;
}

class MistakeEntry {
  const MistakeEntry({
    required this.id,
    required this.original,
    required this.improved,
    required this.explanation,
    required this.category,
    required this.mastered,
  });

  final String id;
  final String original;
  final String improved;
  final String explanation;
  final String category;
  final bool mastered;

  factory MistakeEntry.fromJson(Map<String, Object?> j) => MistakeEntry(
        id: j['id']! as String,
        original: j['original'] as String? ?? '',
        improved: j['improved'] as String? ?? '',
        explanation: j['explanation'] as String? ?? '',
        category: j['category'] as String? ?? 'grammar',
        mastered: j['mastered'] == true,
      );
}

class VocabularyEntry {
  const VocabularyEntry({required this.id, required this.term, required this.meaning, required this.example, required this.learned});

  final String id;
  final String term;
  final String meaning;
  final String example;
  final bool learned;

  factory VocabularyEntry.fromJson(Map<String, Object?> j) => VocabularyEntry(
        id: j['id']! as String,
        term: j['term'] as String? ?? '',
        meaning: j['meaning'] as String? ?? '',
        example: j['example'] as String? ?? '',
        learned: j['learned'] == true,
      );
}

class ProgressDay {
  const ProgressDay(this.date, this.speakingSeconds, this.sessions);
  final String date;
  final int speakingSeconds;
  final int sessions;
}

class RecentSession {
  const RecentSession({required this.id, required this.tutorId, this.scenarioId, required this.startedAt, required this.billedSeconds});
  final String id;
  final String tutorId;
  final String? scenarioId;
  final DateTime startedAt;
  final int billedSeconds;
}

/// Progress tab data: built by the server from recorded activity only (BRAND §7).
class Progress {
  const Progress({
    required this.days,
    required this.totalSpeakingSeconds,
    required this.totalSessions,
    required this.streakDays,
    required this.mistakesOpen,
    required this.mistakesMastered,
    required this.vocabularyTotal,
    required this.vocabularyLearned,
    required this.recentSessions,
  });

  /// Last 30 local days, oldest first.
  final List<ProgressDay> days;
  final int totalSpeakingSeconds;
  final int totalSessions;
  final int streakDays;
  final int mistakesOpen;
  final int mistakesMastered;
  final int vocabularyTotal;
  final int vocabularyLearned;
  final List<RecentSession> recentSessions;

  bool get isEmpty => totalSessions == 0 && recentSessions.isEmpty;

  factory Progress.fromJson(Map<String, Object?> j) {
    Map<String, Object?> m(Object? v) => (v as Map).cast<String, Object?>();
    final totals = m(j['totals']);
    final mistakes = m(j['mistakes']);
    final vocabulary = m(j['vocabulary']);
    return Progress(
      days: [
        for (final d in (j['days'] as List).map(m)) ProgressDay(d['date']! as String, d['speakingSeconds']! as int, d['sessions']! as int),
      ],
      totalSpeakingSeconds: totals['speakingSeconds']! as int,
      totalSessions: totals['sessions']! as int,
      streakDays: j['streakDays']! as int,
      mistakesOpen: mistakes['open']! as int,
      mistakesMastered: mistakes['mastered']! as int,
      vocabularyTotal: vocabulary['total']! as int,
      vocabularyLearned: vocabulary['learned']! as int,
      recentSessions: [
        for (final s in (j['recentSessions'] as List? ?? const []).map(m))
          RecentSession(
            id: s['id']! as String,
            tutorId: s['tutorId']! as String,
            scenarioId: s['scenarioId'] as String?,
            startedAt: DateTime.parse(s['startedAt']! as String),
            billedSeconds: (s['billedSeconds'] as int?) ?? 0,
          ),
      ],
    );
  }
}

/// Learning data for the signed-in user (backend derives the uid from the ID token).
abstract interface class LearningRepository {
  Future<FeedbackResult> getFeedback(String conversationId);
  Future<List<MistakeEntry>> listMistakes();
  Future<void> setMistakeMastered(String id, bool mastered);
  Future<List<VocabularyEntry>> listVocabulary();
  Future<void> setVocabularyLearned(String id, bool learned);
  Future<Progress> getProgress();
}

class ApiLearningRepository implements LearningRepository {
  ApiLearningRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  @override
  Future<FeedbackResult> getFeedback(String conversationId) => _call(() async {
        final res = await _dio.get<Map<String, Object?>>('/api/v1/me/conversations/${Uri.encodeComponent(conversationId)}/feedback');
        final data = res.data!;
        return switch (data['status']) {
          'completed' => FeedbackCompleted(SessionFeedback.fromJson((data['feedback']! as Map).cast<String, dynamic>())),
          'insufficient_speech' => const FeedbackInsufficientSpeech(),
          'failed' => FeedbackFailed(data['message'] is String ? data['message']! as String : 'We could not prepare feedback for this session.'),
          _ => const FeedbackPending(),
        };
      });

  @override
  Future<List<MistakeEntry>> listMistakes() => _call(() async {
        final res = await _dio.get<Map<String, Object?>>('/api/v1/me/mistakes', queryParameters: {'limit': 100});
        return [for (final m in res.data!['mistakes']! as List) MistakeEntry.fromJson((m as Map).cast<String, Object?>())];
      });

  @override
  Future<void> setMistakeMastered(String id, bool mastered) =>
      _call(() => _dio.patch<void>('/api/v1/me/mistakes/${Uri.encodeComponent(id)}', data: {'mastered': mastered}));

  @override
  Future<List<VocabularyEntry>> listVocabulary() => _call(() async {
        final res = await _dio.get<Map<String, Object?>>('/api/v1/me/vocabulary', queryParameters: {'limit': 100});
        return [for (final v in res.data!['vocabulary']! as List) VocabularyEntry.fromJson((v as Map).cast<String, Object?>())];
      });

  @override
  Future<void> setVocabularyLearned(String id, bool learned) =>
      _call(() => _dio.patch<void>('/api/v1/me/vocabulary/${Uri.encodeComponent(id)}', data: {'learned': learned}));

  @override
  Future<Progress> getProgress() => _call(() async {
        final res = await _dio.get<Map<String, Object?>>('/api/v1/me/progress');
        return Progress.fromJson((res.data!['progress']! as Map).cast<String, Object?>());
      });
}

final learningRepositoryProvider = Provider<LearningRepository>((ref) => ApiLearningRepository(ref.watch(apiClientProvider)));

/// Delay between feedback polls (overridden with zero in tests).
final feedbackPollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 2));

/// Polls until feedback is ready (or definitively unavailable). `failed` is shown with a retry.
final feedbackProvider = FutureProvider.autoDispose.family<FeedbackResult, String>((ref, conversationId) async {
  final repo = ref.watch(learningRepositoryProvider);
  final interval = ref.watch(feedbackPollIntervalProvider);
  for (var attempt = 0; attempt < 30; attempt++) {
    final result = await repo.getFeedback(conversationId);
    if (result is! FeedbackPending) {
      if (result is FeedbackCompleted) {
        // New corrections and words were saved: refresh the Learn and Progress tabs.
        ref.invalidate(mistakesProvider);
        ref.invalidate(vocabularyProvider);
        ref.invalidate(progressProvider);
      }
      return result;
    }
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Feedback is taking longer than expected');
});

final mistakesProvider = FutureProvider.autoDispose<List<MistakeEntry>>((ref) => ref.watch(learningRepositoryProvider).listMistakes());
final vocabularyProvider = FutureProvider.autoDispose<List<VocabularyEntry>>((ref) => ref.watch(learningRepositoryProvider).listVocabulary());
final progressProvider = FutureProvider.autoDispose<Progress>((ref) => ref.watch(learningRepositoryProvider).getProgress());
