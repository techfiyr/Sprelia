import '../../core/services/realtime/realtime_provider.dart';
import 'data/conversation_repository.dart';

enum ConversationStatus { idle, connecting, live, ending, ended, failed }

class TranscriptLine {
  const TranscriptLine(this.speaker, this.text);
  final Speaker speaker;
  final String text;

  TranscriptLine append(String delta) => TranscriptLine(speaker, text + delta);

  Map<String, dynamic> toJson() => {
        'speaker': speaker == Speaker.learner ? 'user' : 'tutor',
        'text': text.trim(),
      };
}

class ConversationState {
  const ConversationState({
    this.status = ConversationStatus.idle,
    this.conversationId,
    this.transcript = const [],
    this.elapsedSeconds = 0,
    this.maxSeconds = 0,
    this.muted = false,
    this.tutorSpeaking = false,
    this.lastResponseLatencyMs,
    this.error,
    this.startError,
  });

  final ConversationStatus status;
  final String? conversationId;
  final List<TranscriptLine> transcript;
  final int elapsedSeconds;
  final int maxSeconds;
  final bool muted;
  final bool tutorSpeaking;

  /// Prototype metric: time from the learner's last transcribed speech to the first
  /// tutor audio chunk. Approximate, because it includes transcription delay.
  final int? lastResponseLatencyMs;
  final String? error;

  /// Why the session could not start (e.g. daily limit), when the server said so.
  final ConversationStartError? startError;

  int get remainingSeconds => (maxSeconds - elapsedSeconds).clamp(0, maxSeconds);

  ConversationState copyWith({
    ConversationStatus? status,
    String? conversationId,
    List<TranscriptLine>? transcript,
    int? elapsedSeconds,
    int? maxSeconds,
    bool? muted,
    bool? tutorSpeaking,
    int? lastResponseLatencyMs,
    String? error,
    ConversationStartError? startError,
  }) {
    return ConversationState(
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      transcript: transcript ?? this.transcript,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      maxSeconds: maxSeconds ?? this.maxSeconds,
      muted: muted ?? this.muted,
      tutorSpeaking: tutorSpeaking ?? this.tutorSpeaking,
      lastResponseLatencyMs: lastResponseLatencyMs ?? this.lastResponseLatencyMs,
      error: error ?? this.error,
      startError: startError ?? this.startError,
    );
  }
}
