import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef SpeechResultCallback = void Function(String transcript, bool isFinal);

class AudioPracticeService {
  bool _listening = false;
  String? _recordingPath;

  Future<bool> speak(String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return text.trim().isNotEmpty;
  }

  Future<bool> startListening({required SpeechResultCallback onResult}) async {
    _listening = true;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (_listening) onResult('', true);
    });
    return true;
  }

  Future<void> stopListening() async {
    _listening = false;
  }

  Future<String?> startRecording(String itemId) async {
    final dir = await getTemporaryDirectory();
    _recordingPath = p.join(dir.path, '$itemId.m4a');
    final file = File(_recordingPath!);
    if (!await file.exists()) {
      await file.writeAsString('stub');
    }
    return _recordingPath;
  }

  Future<String?> stopRecording() async {
    return _recordingPath;
  }

  Future<bool> playRecording(String path) async {
    return File(path).existsSync();
  }

  Future<bool> play(String path) => playRecording(path);

  Future<void> stopPlayback() async {}

  Future<void> playHintCue() => SystemSound.play(SystemSoundType.click);
  Future<void> playProgressCue() => SystemSound.play(SystemSoundType.click);
  Future<void> playSuccessCue() => SystemSound.play(SystemSoundType.click);
  Future<void> playWarningCue() => SystemSound.play(SystemSoundType.alert);

  Future<void> dispose() async {
    _listening = false;
  }
}
