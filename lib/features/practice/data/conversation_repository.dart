import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/realtime/realtime_provider.dart';

/// Why a voice session could not start (server error codes, user-safe messages).
enum ConversationStartError {
  dailyLimitReached,
  premiumRequired,
  voiceUnavailable,
  onboardingRequired,
  other,
}

class ConversationStartFailure implements Exception {
  const ConversationStartFailure(this.kind, this.message);
  final ConversationStartError kind;
  final String message;
}

/// Server-side session ending reasons (the backend validates this list).
enum ConversationEndReason {
  userEnded('user_ended'),
  timeLimit('time_limit'),
  connectionLost('connection_lost'),
  error('error'),
  appClosed('app_closed');

  const ConversationEndReason(this.wire);
  final String wire;
}

/// Voice sessions on the backend (`/api/v1/me/conversations`). The server reserves the daily
/// allowance, mints the short-lived realtime grant and bills measured time on end; the app never
/// reports durations.
abstract interface class ConversationRepository {
  Future<RealtimeSessionGrant> start({required String tutorId, String? scenarioId});

  /// Ends the session (idempotent on the server). [transcript] (`{speaker: learner|tutor, text}`)
  /// is uploaded for post-session feedback only. Returns the billed seconds when known.
  Future<int?> end(String conversationId, ConversationEndReason reason, {List<Map<String, Object?>> transcript = const []});
}

class ApiConversationRepository implements ConversationRepository {
  ApiConversationRepository(this._dio);

  final Dio _dio;

  @override
  Future<RealtimeSessionGrant> start({required String tutorId, String? scenarioId}) async {
    try {
      return await _start(tutorId, scenarioId);
    } on _SessionActive catch (active) {
      // A previous session is still open on the server (e.g. the app was closed mid-session).
      // It is the caller's own session: end it, then try once more.
      await end(active.conversationId, ConversationEndReason.appClosed);
      return _start(tutorId, scenarioId);
    }
  }

  Future<RealtimeSessionGrant> _start(String tutorId, String? scenarioId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/api/v1/me/conversations', data: {
        'tutorId': tutorId,
        'scenarioId': ?scenarioId,
      });
      return RealtimeSessionGrant.fromJson(res.data!);
    } catch (e) {
      final failure = AppFailure.from(e);
      if (failure is ServerFailure) {
        if (failure.code == 'SESSION_ACTIVE') {
          final id = _activeId(e);
          if (id != null) throw _SessionActive(id);
        }
        final kind = switch (failure.code) {
          'DAILY_LIMIT_REACHED' => ConversationStartError.dailyLimitReached,
          'PREMIUM_REQUIRED' => ConversationStartError.premiumRequired,
          'VOICE_UNAVAILABLE' => ConversationStartError.voiceUnavailable,
          'ONBOARDING_REQUIRED' => ConversationStartError.onboardingRequired,
          _ => ConversationStartError.other,
        };
        throw ConversationStartFailure(kind, failure.message);
      }
      throw failure;
    }
  }

  static String? _activeId(Object e) {
    if (e is! DioException) return null;
    final data = e.response?.data;
    final error = data is Map ? data['error'] : null;
    final details = error is Map ? error['details'] : null;
    final first = details is List && details.isNotEmpty ? details.first : null;
    final id = first is Map ? first['message'] : null;
    return id is String && RegExp(r'^[0-9a-f-]{36}$').hasMatch(id) ? id : null;
  }

  /// Server limits: 400 lines, 2000 characters each.
  static const _maxLines = 400;
  static const _maxLineLength = 2000;

  @override
  Future<int?> end(String conversationId, ConversationEndReason reason, {List<Map<String, Object?>> transcript = const []}) async {
    final lines = [
      for (final l in transcript.take(_maxLines))
        if ((l['text'] as String? ?? '').trim().isNotEmpty)
          {'speaker': l['speaker'], 'text': _clip((l['text']! as String).trim())},
    ];
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/me/conversations/${Uri.encodeComponent(conversationId)}/end',
        data: {'reason': reason.wire, if (lines.isNotEmpty) 'transcript': lines},
      );
      return (res.data?['conversation'] as Map?)?['billedSeconds'] as int?;
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}

String _clip(String s) => s.length <= ApiConversationRepository._maxLineLength ? s : s.substring(0, ApiConversationRepository._maxLineLength);

class _SessionActive implements Exception {
  const _SessionActive(this.conversationId);
  final String conversationId;
}

final conversationRepositoryProvider =
    Provider<ConversationRepository>((ref) => ApiConversationRepository(ref.watch(apiClientProvider)));
