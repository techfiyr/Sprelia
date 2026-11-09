import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/services/api_client.dart';
import '../../core/services/realtime/audio_io.dart';
import '../../core/services/realtime/gemini_live_provider.dart';
import '../../core/services/realtime/realtime_provider.dart';
import 'conversation_state.dart';

/// Swap this provider to change AI vendors; nothing else in the UI changes.
final realtimeProviderFactory = Provider<RealtimeConversationProvider Function()>(
  (ref) => GeminiLiveProvider.new,
);

final conversationControllerProvider = NotifierProvider.autoDispose
    .family<ConversationController, ConversationState, String>(ConversationController.new);

class ConversationController extends Notifier<ConversationState> {
  ConversationController(this.tutorId);

  final String tutorId;

  RealtimeConversationProvider? _provider;
  final _mic = MicrophoneStream();
  final _player = PcmPlayer();
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<RealtimeEvent>? _eventSub;
  Timer? _ticker;
  Speaker? _lastSpeaker;
  DateTime? _learnerSpokeAt;
  bool _awaitingFirstAudio = false;
  bool _disposed = false;

  @override
  ConversationState build() {
    ref.onDispose(() {
      _disposed = true;
      _teardown();
    });
    return const ConversationState();
  }

  Dio get _api => ref.read(apiClientProvider);

  Future<void> start({String? scenarioId}) async {
    if (state.status == ConversationStatus.connecting || state.status == ConversationStatus.live) {
      return;
    }
    state = const ConversationState(status: ConversationStatus.connecting);

    if (!await _mic.ensurePermission()) {
      _fail('Microphone permission is needed to talk with your tutor.');
      return;
    }

    try {
      final res = await _api.post<Map<String, dynamic>>('/v1/conversations', data: {
        'tutorId': tutorId,
        'scenarioId': ?scenarioId,
        'mode': scenarioId == null ? 'free' : 'scenario',
      });
      final grant = RealtimeSessionGrant.fromJson(res.data!);
      if (_disposed) return;
      state = state.copyWith(conversationId: grant.conversationId, maxSeconds: grant.maxDurationSeconds);

      final provider = ref.read(realtimeProviderFactory)();
      _provider = provider;
      _eventSub = provider.events.listen(_onEvent);
      await _player.init(sampleRate: 24000);
      await provider.connect(grant);
      // The session goes live on RealtimeReady.
      _pendingOpening = grant.openingInstruction;
    } catch (e, st) {
      // Show only user-safe text; the raw error goes to the reporter.
      ref.read(errorReporterProvider).report(e, st, reason: 'Conversation start failed');
      _fail(AppFailure.from(e).message);
    }
  }

  String? _pendingOpening;

  Future<void> _onEvent(RealtimeEvent event) async {
    if (_disposed) return;
    switch (event) {
      case RealtimeReady():
        await _goLive();
      case RealtimeAudio(:final pcm16, :final sampleRate):
        if (_awaitingFirstAudio && _learnerSpokeAt != null) {
          _awaitingFirstAudio = false;
          state = state.copyWith(
            lastResponseLatencyMs: DateTime.now().difference(_learnerSpokeAt!).inMilliseconds,
          );
        }
        if (!state.tutorSpeaking) state = state.copyWith(tutorSpeaking: true);
        await _player.play(pcm16, sampleRate);
      case RealtimeTranscript(:final speaker, :final textDelta):
        _appendTranscript(speaker, textDelta);
        if (speaker == Speaker.learner) {
          _learnerSpokeAt = DateTime.now();
          _awaitingFirstAudio = true;
        }
      case RealtimeInterrupted():
        await _player.clear();
        state = state.copyWith(tutorSpeaking: false);
      case RealtimeTurnComplete():
        state = state.copyWith(tutorSpeaking: false);
      case RealtimeGoingAway():
        // Prototype: let the session end naturally. Session resumption is a later phase.
        break;
      case RealtimeError(:final message):
        _fail(message);
      case RealtimeClosed():
        if (state.status == ConversationStatus.live) {
          await end(reason: 'provider_closed');
        }
    }
  }

  Future<void> _goLive() async {
    final provider = _provider;
    if (provider == null) return;
    state = state.copyWith(status: ConversationStatus.live);

    final mic = await _mic.start(sampleRate: provider.inputSampleRate);
    _micSub = mic.listen((chunk) {
      if (!state.muted) provider.sendAudio(chunk);
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = state.elapsedSeconds + 1;
      state = state.copyWith(elapsedSeconds: elapsed);
      // Client-side stop for UX only; the backend enforces the real limit.
      if (state.maxSeconds > 0 && elapsed >= state.maxSeconds) {
        end(reason: 'limit_reached');
      }
    });

    provider.sendText(_pendingOpening ?? 'Please greet me and start our conversation.');
  }

  void _appendTranscript(Speaker speaker, String delta) {
    final lines = [...state.transcript];
    if (lines.isNotEmpty && _lastSpeaker == speaker) {
      lines[lines.length - 1] = lines.last.append(delta);
    } else {
      lines.add(TranscriptLine(speaker, delta.trimLeft()));
    }
    _lastSpeaker = speaker;
    state = state.copyWith(transcript: lines);
  }

  void toggleMute() => state = state.copyWith(muted: !state.muted);

  Future<void> end({String reason = 'user_ended'}) async {
    if (state.status != ConversationStatus.live && state.status != ConversationStatus.connecting) {
      return;
    }
    state = state.copyWith(status: ConversationStatus.ending);
    await _teardown();

    final id = state.conversationId;
    if (id != null) {
      try {
        await _api.post<void>('/v1/conversations/$id/end', data: {
          'reason': reason,
          'clientElapsedSeconds': state.elapsedSeconds,
          // Prototype: the client uploads the transcript. Production should
          // capture it server-side or validate it before trusting it.
          'transcript': state.transcript.map((l) => l.toJson()).toList(),
        });
      } catch (_) {
        // The backend reconciles usage on token expiry even if this call fails.
      }
    }
    if (!_disposed) state = state.copyWith(status: ConversationStatus.ended);
  }

  void _fail(String message) {
    if (_disposed) return;
    state = state.copyWith(status: ConversationStatus.failed, error: message);
    _teardown();
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _micSub?.cancel();
    _micSub = null;
    await _mic.stop().catchError((_) {});
    await _eventSub?.cancel();
    _eventSub = null;
    await _provider?.disconnect();
    _provider = null;
    await _player.dispose();
  }
}
