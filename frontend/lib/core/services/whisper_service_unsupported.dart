import 'package:flutter/foundation.dart';

class WhisperService {
  WhisperService._privateConstructor();
  static final WhisperService instance = WhisperService._privateConstructor();

  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  bool get isReady => false;

  Future<bool> checkModelsExist() async {
    return false;
  }

  Future<void> downloadModels() async {
    statusNotifier.value = 'Whisper local no está soportado en Web.';
    downloadProgress.value = 0.0;
  }

  Future<void> initWhisper() async {
    statusNotifier.value = 'Whisper local no está soportado en Web.';
  }

  Future<String> transcribe(String audioPath) async {
    throw UnsupportedError('Whisper local no está soportado en Web.');
  }
}
