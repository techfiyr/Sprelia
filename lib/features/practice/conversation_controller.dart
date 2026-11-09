import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/services/realtime/audio_io.dart';
import '../../core/services/realtime/gemini_live_provider.dart';
import '../../core/services/realtime/realtime_provider.dart';
import '../profile/data/profile_repository.dart';
import 'conversation_state.dart';
import 'data/conversation_repository.dart';

/// Swap this provider to change AI vendors; nothing else in the UI changes.
final realtimeProviderFactory = Provider<RealtimeConversationProvider Function()>(
  (ref) => GeminiLiveProvider.new,
);

/// Microphone and speaker factories; overridden with fakes in tests.
final audioInputFactory = Provider<AudioInput Function()>((ref) => MicrophoneStream.new);
final audioOutputFactory = Provider<AudioOutput Function()>((ref) => PcmPlayer.new);

final conversationControllerProvider = NotifierProvider.autoDispose
    .family<ConversationController, ConversationState, String>(ConversationController.new);

/// One live voice session (APP_FLOW §10). The backend reserves the allowance and bills measured
/// time; the client timer is for display and a polite stop only.
class ConversationController extends Notifier<ConversationState> {
  ConversationController(this.tutorId);

  final String tutorId;

  RealtimeConversationProvider? _provider;
  // Created in build(), never lazily: teardown can run after the provider is disposed.
  late AudioInput _mic;
  late AudioOutput _player;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<RealtimeEvent>? _eventSub;
  Timer? _ticker;
  Speaker? _lastSpeaker;
  DateTime? _learnerSpokeAt;
  bool _awaitingFirstAudio = false;
  bool _disposed = false;

  @override
  ConversationState build() {
    _mic = ref.read(audioInputFactory)();
    _player = ref.read(audioOutputFactory)();
    ref.onDispose(() {
      _disposed = true;
      _teardown();
    });
    return const ConversationState();
  }

  ConversationRepository get _repo => ref.read(conversationRepositoryProvider);

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
      final grant = await _repo.start(tutorId: tutorId, scenarioId: scenarioId);
      if (_disposed) {
        await _repo.end(grant.conversationId, ConversationEndReason.appClosed).catchError((_) => null);
        return;
      }
      state = state.copyWith(conversationId: grant.conversationId, maxSeconds: grant.maxDurationSeconds);

      final provider = ref.read(realtimeProviderFactory)();
      _provider = provider;
      _eventSub = provider.events.listen(_onEvent);
      await _player.init(sampleRate: 24000);
      await provider.connect(grant);
      // The session goes live on RealtimeReady.
      _pendingOpening = grant.openingInstruction;
    } on ConversationStartFailure catch (e) {
      _fail(e.message, startError: e.kind);
    } catch (e, st) {
      // Show only user-safe text; the raw error goes to the reporter.
      ref.read(errorReporterProvider).report(e, st, reason: 'Conversation start failed');
      _fail(AppFailure.from(e).message);
      // The grant may exist on the server; end it so it is billed correctly.
      final id = state.conversationId;
      if (id != null) await _repo.end(id, ConversationEndReason.error).catchError((_) => null);
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
      case RealtimeError():
        await end(reason: ConversationEndReason.error, failedMessage: 'The connection to your tutor was lost.');
      case RealtimeClosed():
        if (state.status == ConversationStatus.live) {
          await end(reason: ConversationEndReason.connectionLost);
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
        end(reason: ConversationEndReason.timeLimit);
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

  /// Ends the session. [failedMessage] ends it as a failure (shown to the learner) while still
  /// billing the time actually used.
  Future<void> end({ConversationEndReason reason = ConversationEndReason.userEnded, String? failedMessage}) async {
    if (state.status != ConversationStatus.live && state.status != ConversationStatus.connecting) {
      return;
    }
    state = state.copyWith(status: ConversationStatus.ending);
    await _teardown();

    final id = state.conversationId;
    if (id != null) {
      try {
        await _repo.end(id, reason);
      } catch (_) {
        // The backend reconciles an unended session at its reservation on the next start.
      }
      // Today's remaining time changed.
      ref.invalidate(dashboardProvider);
    }
    if (_disposed) return;
    state = failedMessage == null
        ? state.copyWith(status: ConversationStatus.ended)
        : state.copyWith(status: ConversationStatus.failed, error: failedMessage);
  }

  void _fail(String message, {ConversationStartError? startError}) {
    if (_disposed) return;
    state = state.copyWith(status: ConversationStatus.failed, error: message, startError: startError);
    _teardown();
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _mic.stop();
    } catch (_) {
      // The recorder may already be stopped.
    }
    await _eventSub?.cancel();
    _eventSub = null;
    await _provider?.disconnect();
    _provider = null;
    await _player.dispose();
  }
}
