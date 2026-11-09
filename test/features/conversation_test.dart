import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/errors/app_failure.dart';
import 'package:speakdaily/core/services/realtime/audio_io.dart';
import 'package:speakdaily/core/services/realtime/realtime_provider.dart';
import 'package:speakdaily/features/practice/conversation_controller.dart';
import 'package:speakdaily/features/practice/conversation_state.dart';
import 'package:speakdaily/features/practice/data/conversation_repository.dart';
import 'package:speakdaily/features/profile/data/profile_repository.dart';

import '../helpers/fakes.dart';

/// Phase 6–7: the voice session controller and its backend client, with fakes for the
/// realtime vendor, microphone, speaker and HTTP.
RealtimeSessionGrant _grant({int seconds = 600}) => RealtimeSessionGrant(
      conversationId: '0b9b6f0c-1111-4222-8333-944455556666',
      provider: 'gemini',
      token: 'auth_tokens/fake',
      model: 'gemini-3.8-live',
      websocketUrl: 'wss://example.invalid/live',
      maxDurationSeconds: seconds,
      expiresAt: DateTime.utc(2026, 11, 9, 12),
      openingInstruction: 'Greet me as Sofia.',
    );

class FakeRealtime implements RealtimeConversationProvider {
  // ignore: close_sinks (closed by _Harness.dispose)
  final events$ = StreamController<RealtimeEvent>.broadcast();
  RealtimeSessionGrant? connected;
  final texts = <String>[];
  int audioChunks = 0;
  bool disconnected = false;

  @override
  int get inputSampleRate => 16000;
  @override
  Stream<RealtimeEvent> get events => events$.stream;
  @override
  Future<void> connect(RealtimeSessionGrant grant) async => connected = grant;
  @override
  void sendAudio(Uint8List pcm16) => audioChunks++;
  @override
  void sendText(String text) => texts.add(text);
  @override
  Future<void> disconnect() async => disconnected = true;
}

class FakeMic implements AudioInput {
  bool permission = true;
  // ignore: close_sinks (closed by _Harness.dispose)
  final chunks = StreamController<Uint8List>.broadcast();
  bool stopped = false;
  @override
  Future<bool> ensurePermission() async => permission;
  @override
  Future<Stream<Uint8List>> start({required int sampleRate}) async => chunks.stream;
  @override
  Future<void> stop() async => stopped = true;
}

class FakeSpeaker implements AudioOutput {
  int played = 0;
  int cleared = 0;
  @override
  Future<void> init({required int sampleRate}) async {}
  @override
  Future<void> play(Uint8List pcm16, int sampleRate) async => played++;
  @override
  Future<void> clear() async => cleared++;
  @override
  Future<void> dispose() async {}
}

class FakeConversations implements ConversationRepository {
  RealtimeSessionGrant grant = _grant();
  Object? startError;
  final starts = <(String, String?)>[];
  final ends = <(String, ConversationEndReason)>[];
  @override
  Future<RealtimeSessionGrant> start({required String tutorId, String? scenarioId}) async {
    starts.add((tutorId, scenarioId));
    if (startError != null) throw startError!;
    return grant;
  }

  @override
  Future<int?> end(String conversationId, ConversationEndReason reason) async {
    ends.add((conversationId, reason));
    return 60;
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        realtimeProviderFactory.overrideWithValue(() => realtime),
        audioInputFactory.overrideWithValue(() => mic),
        audioOutputFactory.overrideWithValue(() => speaker),
        conversationRepositoryProvider.overrideWithValue(repo),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      ],
      retry: (_, _) => null,
    );
    sub = container.listen(conversationControllerProvider('sofia'), (_, _) {});
  }

  final realtime = FakeRealtime();
  final mic = FakeMic();
  final speaker = FakeSpeaker();
  final repo = FakeConversations();
  late final ProviderContainer container;
  late final ProviderSubscription<ConversationState> sub;

  Future<void> dispose() async {
    container.dispose();
    await realtime.events$.close();
    await mic.chunks.close();
  }

  ConversationController get controller => container.read(conversationControllerProvider('sofia').notifier);
  ConversationState get state => container.read(conversationControllerProvider('sofia'));
}

void main() {
  test('start → live → transcript and audio → end bills on the server', () async {
    final h = _Harness();
    addTearDown(h.dispose);

    await h.controller.start(scenarioId: 'airport');
    expect(h.repo.starts, [('sofia', 'airport')]);
    expect(h.realtime.connected?.conversationId, h.repo.grant.conversationId);
    expect(h.state.status, ConversationStatus.connecting);

    h.realtime.events$.add(const RealtimeReady());
    await pumpEventQueue();
    expect(h.state.status, ConversationStatus.live);
    expect(h.realtime.texts, ['Greet me as Sofia.']);

    h.mic.chunks.add(Uint8List(320));
    await pumpEventQueue();
    expect(h.realtime.audioChunks, 1);

    h.realtime.events$
      ..add(const RealtimeTranscript(Speaker.tutor, 'Hi! Where are you flying today?'))
      ..add(RealtimeAudio(Uint8List(480), 24000))
      ..add(const RealtimeTranscript(Speaker.learner, 'To London.'));
    await pumpEventQueue();
    expect(h.state.transcript.map((l) => l.text), ['Hi! Where are you flying today?', 'To London.']);
    expect(h.speaker.played, 1);

    await h.controller.end();
    expect(h.repo.ends.single, (h.repo.grant.conversationId, ConversationEndReason.userEnded));
    expect(h.state.status, ConversationStatus.ended);
    expect(h.mic.stopped && h.realtime.disconnected, isTrue);
  });

  test('no microphone permission: nothing is reserved', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.mic.permission = false;
    await h.controller.start();
    expect(h.repo.starts, isEmpty);
    expect(h.state.status, ConversationStatus.failed);
    expect(h.state.error, contains('Microphone'));
  });

  test('daily limit from the server is shown as such', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.repo.startError = const ConversationStartFailure(
      ConversationStartError.dailyLimitReached,
      "You've used today's free speaking time. It resets at midnight.",
    );
    await h.controller.start();
    expect(h.state.status, ConversationStatus.failed);
    expect(h.state.startError, ConversationStartError.dailyLimitReached);
    expect(h.state.error, contains('free speaking time'));
  });

  test('learner interruption drops queued tutor audio', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    h.realtime.events$.add(const RealtimeReady());
    await pumpEventQueue();
    h.realtime.events$.add(const RealtimeInterrupted());
    await pumpEventQueue();
    expect(h.speaker.cleared, 1);
    await h.controller.end();
  });

  test('a dropped connection ends and bills the session', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    h.realtime.events$.add(const RealtimeReady());
    await pumpEventQueue();
    h.realtime.events$.add(const RealtimeClosed(reason: 'network'));
    await pumpEventQueue();
    expect(h.repo.ends.single.$2, ConversationEndReason.connectionLost);
    expect(h.state.status, ConversationStatus.ended);
  });

  test('a provider error ends the session as failed (still billed for time used)', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    h.realtime.events$.add(const RealtimeReady());
    await pumpEventQueue();
    h.realtime.events$.add(const RealtimeError('boom'));
    await pumpEventQueue();
    expect(h.repo.ends.single.$2, ConversationEndReason.error);
    expect(h.state.status, ConversationStatus.failed);
    expect(h.state.error, 'The connection to your tutor was lost.');
  });

  test('the client stops politely at the reserved time', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.repo.grant = _grant(seconds: 1);
    await h.controller.start();
    h.realtime.events$.add(const RealtimeReady());
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    await pumpEventQueue();
    expect(h.repo.ends.single.$2, ConversationEndReason.timeLimit);
    expect(h.state.status, ConversationStatus.ended);
  });

  group('ApiConversationRepository', () {
    test('maps server error codes to start failures', () async {
      for (final (code, kind) in [
        ('DAILY_LIMIT_REACHED', ConversationStartError.dailyLimitReached),
        ('PREMIUM_REQUIRED', ConversationStartError.premiumRequired),
        ('VOICE_UNAVAILABLE', ConversationStartError.voiceUnavailable),
        ('ONBOARDING_REQUIRED', ConversationStartError.onboardingRequired),
      ]) {
        final adapter = _FakeAdapter()..respond('POST', '/api/v1/me/conversations', 403, {'error': {'code': code, 'message': 'msg $code'}});
        final repo = ApiConversationRepository(Dio()..httpClientAdapter = adapter);
        await expectLater(
          repo.start(tutorId: 'sofia'),
          throwsA(isA<ConversationStartFailure>().having((f) => f.kind, 'kind', kind).having((f) => f.message, 'message', 'msg $code')),
        );
      }
    });

    test('recovers from a left-over active session by ending it and retrying once', () async {
      const stale = '11111111-2222-4333-8444-555566667777';
      final adapter = _FakeAdapter()
        ..respond('POST', '/api/v1/me/conversations', 409, {
          'error': {
            'code': 'SESSION_ACTIVE',
            'message': 'You already have a conversation in progress.',
            'details': [
              {'path': 'conversationId', 'message': stale},
            ],
          },
        })
        ..respond('POST', '/api/v1/me/conversations/$stale/end', 200, {
          'conversation': {'billedSeconds': 120},
        })
        ..respond('POST', '/api/v1/me/conversations', 201, {
          'conversationId': '0b9b6f0c-1111-4222-8333-944455556666',
          'allowedDurationSeconds': 480,
          'expiresAt': '2026-11-09T12:00:00Z',
          'realtime': {
            'provider': 'gemini',
            'token': 'auth_tokens/x',
            'model': 'gemini-3.8-live',
            'websocketUrl': 'wss://example.invalid',
            'openingInstruction': 'Hi',
          },
        });
      final repo = ApiConversationRepository(Dio()..httpClientAdapter = adapter);
      final grant = await repo.start(tutorId: 'sofia', scenarioId: 'airport');
      expect(grant.maxDurationSeconds, 480);
      expect(adapter.calls, [
        'POST /api/v1/me/conversations {"tutorId":"sofia","scenarioId":"airport"}',
        'POST /api/v1/me/conversations/$stale/end {"reason":"app_closed"}',
        'POST /api/v1/me/conversations {"tutorId":"sofia","scenarioId":"airport"}',
      ]);
    });

    test('network errors stay user-safe failures', () async {
      final adapter = _FakeAdapter()..fail = true;
      final repo = ApiConversationRepository(Dio()..httpClientAdapter = adapter);
      await expectLater(repo.end('0b9b6f0c-1111-4222-8333-944455556666', ConversationEndReason.userEnded), throwsA(isA<AppFailure>()));
    });
  });
}

/// Minimal Dio adapter: queued responses per method+path, records request bodies.
class _FakeAdapter implements HttpClientAdapter {
  final _responses = <String, List<(int, Object)>>{};
  final calls = <String>[];
  bool fail = false;

  void respond(String method, String path, int status, Object body) =>
      (_responses['$method $path'] ??= []).add((status, body));

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (fail) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    final key = '${options.method} ${options.uri.path}';
    calls.add('$key ${jsonEncode(options.data)}');
    final queue = _responses[key];
    final (status, body) = queue == null || queue.isEmpty ? (404, {'error': {'code': 'NOT_FOUND'}}) : queue.removeAt(0);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}
