import 'dart:typed_data';

/// Connection details issued by the SpeakDaily backend for one conversation.
/// Contains only short-lived credentials, never a permanent provider key.
class RealtimeSessionGrant {
  const RealtimeSessionGrant({
    required this.conversationId,
    required this.provider,
    required this.token,
    required this.model,
    required this.websocketUrl,
    required this.maxDurationSeconds,
    required this.expiresAt,
    this.openingInstruction,
  });

  final String conversationId;
  final String provider;
  final String token;
  final String model;
  final String websocketUrl;
  final int maxDurationSeconds;
  final DateTime expiresAt;

  /// Text sent to the model as the first turn so the tutor greets the learner.
  final String? openingInstruction;

  factory RealtimeSessionGrant.fromJson(Map<String, dynamic> json) {
    final realtime = json['realtime'] as Map<String, dynamic>;
    return RealtimeSessionGrant(
      conversationId: json['conversationId'] as String,
      provider: realtime['provider'] as String,
      token: realtime['token'] as String,
      model: realtime['model'] as String,
      websocketUrl: realtime['websocketUrl'] as String,
      openingInstruction: realtime['openingInstruction'] as String?,
      maxDurationSeconds: json['allowedDurationSeconds'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

enum Speaker { learner, tutor }

/// Events emitted by a realtime provider, independent of the vendor.
sealed class RealtimeEvent {
  const RealtimeEvent();
}

class RealtimeReady extends RealtimeEvent {
  const RealtimeReady();
}

/// Output audio as PCM16 little-endian mono at [sampleRate].
class RealtimeAudio extends RealtimeEvent {
  const RealtimeAudio(this.pcm16, this.sampleRate);
  final Uint8List pcm16;
  final int sampleRate;
}

/// Incremental transcript text for the current turn of [speaker].
class RealtimeTranscript extends RealtimeEvent {
  const RealtimeTranscript(this.speaker, this.textDelta);
  final Speaker speaker;
  final String textDelta;
}

/// The learner started speaking over the tutor; queued tutor audio must be dropped.
class RealtimeInterrupted extends RealtimeEvent {
  const RealtimeInterrupted();
}

class RealtimeTurnComplete extends RealtimeEvent {
  const RealtimeTurnComplete();
}

/// The provider will close soon (e.g. server-side session limit).
class RealtimeGoingAway extends RealtimeEvent {
  const RealtimeGoingAway(this.timeLeft);
  final Duration? timeLeft;
}

class RealtimeError extends RealtimeEvent {
  const RealtimeError(this.message);
  final String message;
}

class RealtimeClosed extends RealtimeEvent {
  const RealtimeClosed({this.reason});
  final String? reason;
}

/// Contract every realtime AI vendor implements. UI code depends only on this.
abstract class RealtimeConversationProvider {
  /// Sample rate expected by [sendAudio] (PCM16 mono).
  int get inputSampleRate;

  Stream<RealtimeEvent> get events;

  Future<void> connect(RealtimeSessionGrant grant);

  /// Send a chunk of learner microphone audio (PCM16 LE mono).
  void sendAudio(Uint8List pcm16);

  /// Send a text instruction or message (e.g. ask the tutor to open the conversation).
  void sendText(String text);

  Future<void> disconnect();
}
