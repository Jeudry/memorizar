import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'local_llm_service.dart';

/// Punto de entrada del isolate de Whisper. Crea el recognizer (carga el modelo
/// en ESTE isolate) y atiende peticiones de decode por puerto. Correr el
/// `decode()` —que es una llamada nativa síncrona y pesada— fuera del isolate de
/// la UI evita que la app se congele mientras "Evaluando audio…".
void _whisperIsolateEntry(List<Object> args) {
  final SendPort mainPort = args[0] as SendPort;
  final String encoder = args[1] as String;
  final String decoder = args[2] as String;
  final String tokens = args[3] as String;
  final int numThreads = args[4] as int;

  sherpa_onnx.initBindings();
  final recognizer = sherpa_onnx.OfflineRecognizer(
    sherpa_onnx.OfflineRecognizerConfig(
      model: sherpa_onnx.OfflineModelConfig(
        whisper: sherpa_onnx.OfflineWhisperModelConfig(
          encoder: encoder,
          decoder: decoder,
          language: 'es',
          task: 'transcribe',
          tailPaddings: -1,
        ),
        tokens: tokens,
        modelType: 'whisper',
        numThreads: numThreads,
      ),
    ),
  );

  final commandPort = ReceivePort();
  // Devuelve el puerto de comandos al isolate principal (handshake de "listo").
  mainPort.send(commandPort.sendPort);

  commandPort.listen((dynamic msg) {
    if (msg is List && msg.isNotEmpty && msg[0] == 'decode') {
      final samples = msg[1] as Float32List;
      final reply = msg[2] as SendPort;
      try {
        final stream = recognizer.createStream();
        stream.acceptWaveform(samples: samples, sampleRate: 16000);
        recognizer.decode(stream);
        final text = recognizer.getResult(stream).text;
        stream.free();
        reply.send(text);
      } catch (e) {
        reply.send('__ERROR__$e');
      }
    } else if (msg == 'dispose') {
      recognizer.free();
      commandPort.close();
      Isolate.exit();
    }
  });
}

class WhisperService {
  WhisperService._privateConstructor();
  static final WhisperService instance = WhisperService._privateConstructor();

  static const String _baseUrl = 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small/resolve/main/';
  static const String _encoderFile = 'small-encoder.int8.onnx';
  static const String _decoderFile = 'small-decoder.int8.onnx';
  static const String _tokensFile = 'small-tokens.txt';

  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  // El decode corre en un isolate propio que retiene el modelo (~370 MB). Se
  // mata tras un rato sin transcribir (o al ir la app a segundo plano) para no
  // comer RAM —clave en móvil— y se re-levanta on-demand.
  Isolate? _isolate;
  SendPort? _cmdPort;
  Future<SendPort>? _spawning;
  Timer? _idleTimer;
  static const Duration _idleTimeout = Duration(seconds: 90);

  bool get isReady => _cmdPort != null;

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

  /// Arranca (o reutiliza) el isolate de Whisper con el modelo cargado.
  Future<void> initWhisper() async {
    await _ensureIsolate();
  }

  Future<SendPort> _ensureIsolate() {
    if (_cmdPort != null) return Future.value(_cmdPort!);
    return _spawning ??= _spawnIsolate().whenComplete(() => _spawning = null);
  }

  Future<SendPort> _spawnIsolate() async {
    statusNotifier.value = 'Inicializando motor de voz...';
    final dir = await _modelDirectory;
    final handshake = ReceivePort();
    _isolate = await Isolate.spawn(_whisperIsolateEntry, <Object>[
      handshake.sendPort,
      '${dir.path}/$_encoderFile',
      '${dir.path}/$_decoderFile',
      '${dir.path}/$_tokensFile',
      // whisper-small en CPU es pesado; usamos varios núcleos (con margen).
      Platform.numberOfProcessors.clamp(2, 6),
    ]);
    final cmdPort = await handshake.first as SendPort;
    handshake.close();
    _cmdPort = cmdPort;
    statusNotifier.value = 'Motor listo.';
    debugPrint('Whisper isolate listo (modelo cargado fuera de la UI).');
    return cmdPort;
  }

  /// Mata el isolate y libera el modelo de memoria. La próxima transcripción
  /// lo re-levanta automáticamente.
  Future<void> dispose() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final cmd = _cmdPort;
    final iso = _isolate;
    _cmdPort = null;
    _isolate = null;
    if (cmd == null && iso == null) return;
    try {
      cmd?.send('dispose'); // el isolate libera el recognizer y sale solo
    } catch (_) {}
    // Backstop: si no salió por su cuenta, mátalo.
    if (iso != null) {
      Future.delayed(const Duration(milliseconds: 600),
          () => iso.kill(priority: Isolate.immediate));
    }
    statusNotifier.value = 'Motor de voz en reposo (memoria liberada).';
    debugPrint('Whisper isolate liberado por inactividad.');
  }

  void _armIdleRelease() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () => unawaited(dispose()));
  }

  Future<String> transcribe(String audioPath) async {
    // Estamos usando el motor: cancela cualquier liberación pendiente.
    _idleTimer?.cancel();

    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Archivo de audio no encontrado: $audioPath');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return '';

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
    debugPrint('Whisper: audio de ${audioSeconds}s → decode en isolate…');

    final cmd = await _ensureIsolate();

    // Pausa el prefetch de la IA local (llama-server) durante el decode: aunque
    // ahora corre en otro isolate, ambos compiten por la CPU.
    LocalLlmService.instance.setVoiceCaptureActive(true);
    final sw = Stopwatch()..start();
    try {
      final reply = ReceivePort();
      cmd.send(<Object>['decode', floatSamples, reply.sendPort]);
      final result = await reply.first;
      reply.close();
      sw.stop();
      if (result is String && result.startsWith('__ERROR__')) {
        throw Exception('Whisper decode: ${result.substring(9)}');
      }
      final text = (result as String).trim();
      debugPrint(
          'Whisper: decode de ${audioSeconds}s tardó ${sw.elapsedMilliseconds} ms → "$text"');
      return _sanitizeTranscription(text);
    } finally {
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
