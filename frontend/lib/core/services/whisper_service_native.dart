import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'local_llm_service.dart';

class WhisperService {
  WhisperService._privateConstructor();
  static final WhisperService instance = WhisperService._privateConstructor();

  static const String _baseUrl = 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small/resolve/main/';
  static const String _encoderFile = 'small-encoder.int8.onnx';
  static const String _decoderFile = 'small-decoder.int8.onnx';
  static const String _tokensFile = 'small-tokens.txt';

  bool _initialized = false;
  sherpa_onnx.OfflineRecognizer? _recognizer;
  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  // El modelo whisper-small en memoria ronda los ~370 MB. Se libera tras un
  // rato sin transcribir (o al ir la app a segundo plano) para no comer RAM
  // —clave en móvil— y se recarga on-demand en la siguiente transcripción.
  Timer? _idleTimer;
  static const Duration _idleTimeout = Duration(seconds: 90);

  bool get isReady => _initialized && _recognizer != null;

  /// Libera el recognizer y su modelo de memoria. La próxima transcripción
  /// re-inicializa automáticamente.
  Future<void> dispose() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (_recognizer == null && !_initialized) return;
    try {
      _recognizer?.free();
    } catch (e) {
      debugPrint('Error liberando recognizer Whisper: $e');
    }
    _recognizer = null;
    _initialized = false;
    statusNotifier.value = 'Motor de voz en reposo (memoria liberada).';
    debugPrint('Whisper recognizer liberado por inactividad.');
  }

  void _armIdleRelease() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () => unawaited(dispose()));
  }

  Future<Directory> get _modelDirectory async {
    final docDir = await getApplicationSupportDirectory();
    final modelDir = Directory('${docDir.path}/whisper_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  Future<bool> checkModelsExist() async {
    final dir = await _modelDirectory;
    final encoder = File('${dir.path}/$_encoderFile');
    final decoder = File('${dir.path}/$_decoderFile');
    final tokens = File('${dir.path}/$_tokensFile');

    return await encoder.exists() && await decoder.exists() && await tokens.exists();
  }

  Future<void> downloadModels() async {
    final dir = await _modelDirectory;
    final dio = Dio();

    final filesToDownload = {
      _encoderFile: 112.0 * 1024 * 1024,
      _decoderFile: 262.0 * 1024 * 1024,
      _tokensFile: 1.0 * 1024 * 1024,
    };

    double totalBytesToDownload = filesToDownload.values.fold<double>(0.0, (sum, val) => sum + val);
    double accumulatedDownloadedBytes = 0.0;

    for (final entry in filesToDownload.entries) {
      final fileName = entry.key;
      final fileUrl = '$_baseUrl$fileName';
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        final length = await file.length();
        if (length > 100 * 1024) {
          accumulatedDownloadedBytes += entry.value;
          continue;
        }
      }

      statusNotifier.value = 'Descargando $fileName...';
      debugPrint('Downloading: $fileUrl to $savePath');

      double lastFileProgress = 0.0;
      await dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            double currentFileProgress = received.toDouble();
            double progressDiff = currentFileProgress - lastFileProgress;
            lastFileProgress = currentFileProgress;

            accumulatedDownloadedBytes += progressDiff;
            double progress = (accumulatedDownloadedBytes / totalBytesToDownload).clamp(0.0, 1.0);
            downloadProgress.value = progress;
          }
        },
      );
    }

    downloadProgress.value = 1.0;
    statusNotifier.value = 'Modelos descargados con éxito.';
  }

  Future<void> initWhisper() async {
    if (_initialized) return;

    statusNotifier.value = 'Inicializando motor local...';
    final dir = await _modelDirectory;

    final encoderPath = '${dir.path}/$_encoderFile';
    final decoderPath = '${dir.path}/$_decoderFile';
    final tokensPath = '${dir.path}/$_tokensFile';

    sherpa_onnx.initBindings();

    final whisperConfig = sherpa_onnx.OfflineWhisperModelConfig(
      encoder: encoderPath,
      decoder: decoderPath,
      language: 'es',
      task: 'transcribe',
      tailPaddings: -1,
    );

    final modelConfig = sherpa_onnx.OfflineModelConfig(
      whisper: whisperConfig,
      tokens: tokensPath,
      modelType: 'whisper',
      // whisper-small en CPU es el cuello de botella del "Evaluando audio…".
      // Con 2 hilos infrautilizaba el equipo; escalamos con los núcleos
      // disponibles (dejando margen para la UI) para acelerar la decodificación.
      numThreads: Platform.numberOfProcessors.clamp(2, 6),
      debug: kDebugMode,
    );

    final config = sherpa_onnx.OfflineRecognizerConfig(
      model: modelConfig,
    );

    _recognizer = sherpa_onnx.OfflineRecognizer(config);
    _initialized = true;
    statusNotifier.value = 'Motor listo.';
    debugPrint('Whisper Local Offline Recognizer initialized successfully.');
  }

  Future<String> transcribe(String audioPath) async {
    // Estamos usando el motor: cancela cualquier liberación pendiente.
    _idleTimer?.cancel();
    if (!_initialized || _recognizer == null) {
      throw Exception('Whisper no está inicializado.');
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Archivo de audio no encontrado: $audioPath');
    }

    debugPrint('Starting transcription for audio file: $audioPath');
    
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return '';
    }

    Uint8List pcmBytes = bytes;
    if (bytes.length >= 44 &&
        bytes[0] == 82 &&
        bytes[1] == 73 &&
        bytes[2] == 70 &&
        bytes[3] == 70) {
      pcmBytes = bytes.sublist(44);
    }

    final Float32List floatSamples = _pcm16ToFloat32(pcmBytes);
    final audioSeconds = (floatSamples.length / 16000).toStringAsFixed(1);
    debugPrint(
        'Whisper: audio de ${audioSeconds}s (${floatSamples.length} samples). Decodificando…');

    final recognizer = _recognizer!;
    final stream = recognizer.createStream();

    // Pausa el prefetch de la IA local (llama-server) durante el decode: whisper
    // corre en CPU y, si compiten, el "Evaluando audio…" se eterniza.
    LocalLlmService.instance.setVoiceCaptureActive(true);
    final sw = Stopwatch()..start();
    try {
      stream.acceptWaveform(samples: floatSamples, sampleRate: 16000);
      recognizer.decode(stream);
      final text = recognizer.getResult(stream).text;

      sw.stop();
      debugPrint(
          'Whisper: decode de ${audioSeconds}s tardó ${sw.elapsedMilliseconds} ms → "$text"');
      return _sanitizeTranscription(text.trim());
    } catch (e) {
      debugPrint('Error transcribing audio with Whisper: $e');
      rethrow;
    } finally {
      stream.free();
      LocalLlmService.instance.setVoiceCaptureActive(false);
      // Terminada la transcripción, programa la liberación por inactividad.
      _armIdleRelease();
    }
  }

  String _sanitizeTranscription(String text) {
    if (text.isEmpty) return '';
    
    String cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    List<String> words = cleanText.split(' ');
    if (words.length < 2) return cleanText;

    bool changed = true;
    while (changed) {
      changed = false;
      for (int len = (words.length ~/ 2).clamp(1, 8); len >= 1; len--) {
        for (int i = 0; i <= words.length - 2 * len; i++) {
          bool match = true;
          for (int k = 0; k < len; k++) {
            final w1 = words[i + k].toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
            final w2 = words[i + len + k].toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
            if (w1 != w2) {
              match = false;
              break;
            }
          }
          if (match) {
            words.removeRange(i + len, i + 2 * len);
            changed = true;
            break;
          }
        }
        if (changed) break;
      }
    }
    return words.join(' ');
  }

  Float32List _pcm16ToFloat32(Uint8List bytes) {
    final buffer = bytes.buffer;
    final int16List = buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
    final floatList = Float32List(int16List.length);

    for (var i = 0; i < int16List.length; i++) {
      floatList[i] = int16List[i] / 32768.0;
    }

    return floatList;
  }
}
