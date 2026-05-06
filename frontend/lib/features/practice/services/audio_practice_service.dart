import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioPracticeService {
  AudioPracticeService()
      : _tts = FlutterTts(),
        _recorder = AudioRecorder(),
        _player = AudioPlayer(),
        _speech = SpeechToText() {
    _configureTts();
  }

  final FlutterTts _tts;
  final AudioRecorder _recorder;
  final AudioPlayer _player;
  final SpeechToText _speech;

  Future<void> _configureTts() async {
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.42);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<bool> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<String?> startRecording(String itemId) async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return null;

      final path = await _buildAudioPath(itemId);
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (_) {
      return null;
    }
  }

  Future<int> estimateDurationMs(String? path) async {
    if (path == null) return 0;
    final file = File(path);
    if (!await file.exists()) return 0;
    final length = await file.length();
    return (length / 32).round();
  }

  Future<bool> play(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopPlayback() => _player.stop();

  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  }) async {
    try {
      final available = await _speech.initialize();
      if (!available) return false;
      await _speech.listen(
        localeId: 'es_ES',
        listenOptions: SpeechListenOptions(partialResults: true),
        onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Ignore plugin-specific stop failures.
    }
  }

  Future<String> _buildAudioPath(String itemId) async {
    if (kIsWeb) return '$itemId-recording.m4a';
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(dir.path, 'practice_audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return p.join(audioDir.path, '${itemId}_${DateTime.now().millisecondsSinceEpoch}.m4a');
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _tts.stop();
    await _recorder.dispose();
  }
}
