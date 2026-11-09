import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'realtime_provider.dart';

/// Gemini Live API over WebSocket, authenticated with a backend-issued
/// ephemeral token. The model, system prompt and voice are locked into the
/// token by the backend, so the client setup message stays minimal.
class GeminiLiveProvider implements RealtimeConversationProvider {
  static const _outputSampleRate = 24000;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _events = StreamController<RealtimeEvent>.broadcast();
  bool _ready = false;

  @override
  int get inputSampleRate => 16000;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect(RealtimeSessionGrant grant) async {
    final uri = Uri.parse(grant.websocketUrl).replace(
      queryParameters: {'access_token': grant.token},
    );
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    await channel.ready;

    _sub = channel.stream.listen(
      _onMessage,
      onError: (Object e) => _events.add(RealtimeError('Connection error: $e')),
      onDone: () {
        _ready = false;
        _events.add(RealtimeClosed(reason: channel.closeReason));
      },
    );

    _send({
      'setup': {
        'model': grant.model.startsWith('models/') ? grant.model : 'models/${grant.model}',
        'generationConfig': {'responseModalities': ['AUDIO']},
        'inputAudioTranscription': <String, dynamic>{},
        'outputAudioTranscription': <String, dynamic>{},
      },
    });
  }

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> msg;
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      msg = jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      _events.add(RealtimeError('Malformed server message'));
      return;
    }

    if (msg.containsKey('setupComplete')) {
      _ready = true;
      _events.add(const RealtimeReady());
      return;
    }

    final goAway = msg['goAway'] as Map<String, dynamic>?;
    if (goAway != null) {
      _events.add(RealtimeGoingAway(_parseDuration(goAway['timeLeft'] as String?)));
    }

    final content = msg['serverContent'] as Map<String, dynamic>?;
    if (content == null) return;

    if (content['interrupted'] == true) {
      _events.add(const RealtimeInterrupted());
    }

    final input = content['inputTranscription'] as Map<String, dynamic>?;
    final inputText = input?['text'] as String?;
    if (inputText != null && inputText.isNotEmpty) {
      _events.add(RealtimeTranscript(Speaker.learner, inputText));
    }

    final output = content['outputTranscription'] as Map<String, dynamic>?;
    final outputText = output?['text'] as String?;
    if (outputText != null && outputText.isNotEmpty) {
      _events.add(RealtimeTranscript(Speaker.tutor, outputText));
    }

    final parts = (content['modelTurn'] as Map<String, dynamic>?)?['parts'] as List<dynamic>?;
    for (final part in parts ?? const []) {
      final inline = (part as Map<String, dynamic>)['inlineData'] as Map<String, dynamic>?;
      final data = inline?['data'] as String?;
      if (data != null) {
        _events.add(RealtimeAudio(base64Decode(data), _outputSampleRate));
      }
    }

    if (content['turnComplete'] == true) {
      _events.add(const RealtimeTurnComplete());
    }
  }

  @override
  void sendAudio(Uint8List pcm16) {
    if (!_ready) return;
    _send({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm16),
          'mimeType': 'audio/pcm;rate=$inputSampleRate',
        },
      },
    });
  }

  @override
  void sendText(String text) {
    if (!_ready) return;
    _send({
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turnComplete': true,
      },
    });
  }

  void _send(Map<String, dynamic> message) => _channel?.sink.add(jsonEncode(message));

  @override
  Future<void> disconnect() async {
    _ready = false;
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    if (!_events.isClosed) await _events.close();
  }

  static Duration? _parseDuration(String? value) {
    // Protobuf Duration JSON, e.g. "12.5s".
    if (value == null || !value.endsWith('s')) return null;
    final seconds = double.tryParse(value.substring(0, value.length - 1));
    return seconds == null ? null : Duration(milliseconds: (seconds * 1000).round());
  }
}
