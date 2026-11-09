import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart' hide IosAudioCategory;

/// Microphone input (PCM16 LE mono). Abstract so conversations can be tested without plugins.
abstract interface class AudioInput {
  Future<bool> ensurePermission();
  Future<Stream<Uint8List>> start({required int sampleRate});
  Future<void> stop();
}

/// Speaker output for PCM16 LE mono tutor audio.
abstract interface class AudioOutput {
  Future<void> init({required int sampleRate});
  Future<void> play(Uint8List pcm16, int sampleRate);

  /// Drop queued audio (used when the learner interrupts the tutor).
  Future<void> clear();
  Future<void> dispose();
}

/// Microphone capture (PCM16 mono) with echo cancellation for speakerphone use.
class MicrophoneStream implements AudioInput {
  final _recorder = AudioRecorder();

  @override
  Future<bool> ensurePermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start({required int sampleRate}) {
    return _recorder.startStream(RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      autoGain: true,
      androidConfig: const AndroidRecordConfig(
        audioSource: AndroidAudioSource.voiceCommunication,
        speakerphone: true,
        audioManagerMode: AudioManagerMode.modeInCommunication,
      ),
    ));
  }

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  Future<void> dispose() => _recorder.dispose();
}

/// Streams PCM16 tutor audio to the speaker. [clear] drops queued audio on interruption.
class PcmPlayer implements AudioOutput {
  bool _initialized = false;
  int _sampleRate = 24000;

  @override
  Future<void> init({required int sampleRate}) async {
    _sampleRate = sampleRate;
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playAndRecord,
    );
    await FlutterPcmSound.setFeedThreshold(sampleRate ~/ 10);
    FlutterPcmSound.setFeedCallback((_) {});
    _initialized = true;
  }

  @override
  Future<void> play(Uint8List pcm16, int sampleRate) async {
    if (!_initialized || sampleRate != _sampleRate) {
      await init(sampleRate: sampleRate);
    }
    final aligned = pcm16.lengthInBytes.isEven ? pcm16 : pcm16.sublist(0, pcm16.lengthInBytes - 1);
    await FlutterPcmSound.feed(
      PcmArrayInt16(bytes: ByteData.sublistView(Uint8List.fromList(aligned))),
    );
  }

  @override
  Future<void> clear() async {
    if (!_initialized) return;
    await FlutterPcmSound.release();
    _initialized = false;
  }

  @override
  Future<void> dispose() async {
    if (_initialized) await FlutterPcmSound.release();
    _initialized = false;
  }
}
