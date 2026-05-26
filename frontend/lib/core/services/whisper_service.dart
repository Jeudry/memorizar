import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class WhisperService {
  WhisperService._privateConstructor();
  static final WhisperService instance = WhisperService._privateConstructor();

  // URLs de descarga para los modelos Whisper Small multilenguaje cuantizados (INT8)
  static const String _baseUrl = 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small/resolve/main/';
  static const String _encoderFile = 'small-encoder.int8.onnx';
  static const String _decoderFile = 'small-decoder.int8.onnx';
  static const String _tokensFile = 'small-tokens.txt';


  bool _initialized = false;
  sherpa_onnx.OfflineRecognizer? _recognizer;
  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  bool get isReady => _initialized && _recognizer != null;

  /// Obtiene el directorio local de almacenamiento para los modelos.
  Future<Directory> get _modelDirectory async {
    final docDir = await getApplicationSupportDirectory();
    final modelDir = Directory('${docDir.path}/whisper_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Comprueba si los modelos ya están descargados localmente.
  Future<bool> checkModelsExist() async {
    final dir = await _modelDirectory;
    final encoder = File('${dir.path}/$_encoderFile');
    final decoder = File('${dir.path}/$_decoderFile');
    final tokens = File('${dir.path}/$_tokensFile');

    return await encoder.exists() && await decoder.exists() && await tokens.exists();
  }

  /// Descarga dinámica de los modelos ONNX.
  Future<void> downloadModels() async {
    final dir = await _modelDirectory;
    final dio = Dio();

    final filesToDownload = {
      _encoderFile: 112.0 * 1024 * 1024, // Aprox ~112 MB
      _decoderFile: 262.0 * 1024 * 1024, // Aprox ~262 MB
      _tokensFile: 1.0 * 1024 * 1024,    // Aprox ~1 MB
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
        if (length > 100 * 1024) { // Archivo descargado previamente válido
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

  /// Inicializa los bindings nativos y el OfflineRecognizer.
  Future<void> initWhisper() async {
    if (_initialized) return;

    statusNotifier.value = 'Inicializando motor local...';
    final dir = await _modelDirectory;

    final encoderPath = '${dir.path}/$_encoderFile';
    final decoderPath = '${dir.path}/$_decoderFile';
    final tokensPath = '${dir.path}/$_tokensFile';

    // Inicializar bindings nativos de sherpa-onnx
    sherpa_onnx.initBindings();

    final whisperConfig = sherpa_onnx.OfflineWhisperModelConfig(
      encoder: encoderPath,
      decoder: decoderPath,
      language: 'es', // Forzar español para memorizar versos de la Biblia
      task: 'transcribe',
      tailPaddings: -1,
    );

    final modelConfig = sherpa_onnx.OfflineModelConfig(
      whisper: whisperConfig,
      tokens: tokensPath,
      modelType: 'whisper',
      numThreads: 2, // 2 hilos es el balance óptimo en móviles
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

  /// Transcribe un archivo de audio PCM 16kHz Mono.
  /// Lee el archivo temporal guardado por `record` y lo procesa.
  Future<String> transcribe(String audioPath) async {
    if (!_initialized || _recognizer == null) {
      throw Exception('Whisper no está inicializado.');
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Archivo de audio no encontrado: $audioPath');
    }

    debugPrint('Starting transcription for audio file: $audioPath');
    
    // Leer bytes de audio puros (PCM 16-bit Mono, 16000Hz)
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return '';
    }

    // Si es un archivo WAV, omitir los primeros 44 bytes de cabecera
    Uint8List pcmBytes = bytes;
    if (bytes.length >= 44 &&
        bytes[0] == 82 && // 'R'
        bytes[1] == 73 && // 'I'
        bytes[2] == 70 && // 'F'
        bytes[3] == 70) { // 'F'
      pcmBytes = bytes.sublist(44);
    }

    // Convertir PCM 16-bit a Float32List
    final Float32List floatSamples = _pcm16ToFloat32(pcmBytes);
    debugPrint('Read ${floatSamples.length} float samples from audio file.');

    // Ejecutar inferencia
    final recognizer = _recognizer!;
    final stream = recognizer.createStream();
    
    try {
      stream.acceptWaveform(samples: floatSamples, sampleRate: 16000);
      recognizer.decode(stream);
      final text = recognizer.getResult(stream).text;
      
      debugPrint('Whisper transcription result: "$text"');
      return _sanitizeTranscription(text.trim());
    } catch (e) {
      debugPrint('Error transcribing audio with Whisper: $e');
      rethrow;
    } finally {
      stream.free();
    }
  }

  /// Elimina alucinaciones repetitivas de palabras o frases consecutivas.
  String _sanitizeTranscription(String text) {
    if (text.isEmpty) return '';
    
    // Normalizar espaciado
    String cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    List<String> words = cleanText.split(' ');
    if (words.length < 2) return cleanText;

    bool changed = true;
    while (changed) {
      changed = false;
      // Buscar subsecuencias consecutivas duplicadas de longitud len (de 8 a 1)
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
            // Eliminar duplicado consecutivo
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

  /// Convierte bytes de audio PCM 16-bit en muestras Float32 (de -1.0 a 1.0)
  Float32List _pcm16ToFloat32(Uint8List bytes) {
    final buffer = bytes.buffer;
    final int16List = buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
    final floatList = Float32List(int16List.length);

    for (var i = 0; i < int16List.length; i++) {
      // Normalizar rango -32768 a 32767 a float [-1.0, 1.0]
      floatList[i] = int16List[i] / 32768.0;
    }

    return floatList;
  }
}
