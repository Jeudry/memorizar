import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Administra el ciclo de vida del proceso local `llama-server` (llama.cpp)
/// en plataformas de escritorio. Usa un puerto fijo para que varias
/// instancias de la app (p. ej. pruebas cooperativas multi-ventana)
/// compartan el mismo motor en lugar de cargar el modelo dos veces.
class LlamaServerManager {
  LlamaServerManager._privateConstructor();
  static final LlamaServerManager instance =
      LlamaServerManager._privateConstructor();

  static const int _port = 8731;
  static const String _envBinaryPath =
      String.fromEnvironment('LLAMA_SERVER_PATH', defaultValue: '');
  static const Duration _startupTimeout = Duration(minutes: 3);
  static const Duration _healthPollInterval = Duration(milliseconds: 600);
  static const String _contextSize = '4096';
  static const String _gpuLayers = '99';

  static const List<String> _binaryCandidates = [
    '/opt/homebrew/bin/llama-server',
    '/usr/local/bin/llama-server',
    '/usr/bin/llama-server',
  ];

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 2),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Process? _process;
  bool _processExited = false;

  String get baseUrl => 'http://127.0.0.1:$_port';

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows);

  /// Comprueba si ya hay un servidor sano respondiendo en el puerto fijo
  /// (puede haber sido lanzado por esta instancia o por otra).
  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get('$baseUrl/health');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Garantiza que haya un `llama-server` sirviendo [modelPath]. Si ya hay
  /// uno sano lo reutiliza; si no, lo arranca y espera a que cargue el modelo.
  Future<void> ensureRunning(
    String modelPath, {
    void Function(String status)? onStatus,
  }) async {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'La IA local solo está disponible en escritorio por ahora.',
      );
    }

    final alreadyHealthy = await isHealthy();
    if (alreadyHealthy) return;

    final binaryPath = await _findBinary();
    if (binaryPath == null) {
      throw StateError(
        'No se encontró el binario llama-server. '
        'Instálalo con "brew install llama.cpp" o define LLAMA_SERVER_PATH.',
      );
    }

    onStatus?.call('Arrancando motor de IA local…');
    await _spawn(binaryPath, modelPath);

    onStatus?.call('Cargando Gemma 3 (QAT) en GPU…');
    await _waitUntilHealthy();
  }

  Future<void> _spawn(String binaryPath, String modelPath) async {
    _processExited = false;
    _process = await Process.start(binaryPath, [
      '-m', modelPath,
      '--host', '127.0.0.1',
      '--port', '$_port',
      '-ngl', _gpuLayers,
      '-c', _contextSize,
      '--no-webui',
    ]);
    _process!.exitCode.then((code) {
      _processExited = true;
      debugPrint('llama-server terminó con código $code');
    });
    // Drenar stdout/stderr para que el proceso no se bloquee por backpressure.
    _process!.stdout.listen((_) {});
    _process!.stderr.listen((_) {});
  }

  Future<void> _waitUntilHealthy() async {
    final deadline = DateTime.now().add(_startupTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_processExited) {
        _process = null;
        throw StateError(
          'El motor de IA local terminó inesperadamente al arrancar. '
          'Revisa que el modelo descargado no esté corrupto.',
        );
      }
      final healthy = await isHealthy();
      if (healthy) return;
      await Future.delayed(_healthPollInterval);
    }
    _process?.kill();
    _process = null;
    throw TimeoutException('El motor de IA local no respondió a tiempo.');
  }

  Future<String?> _findBinary() async {
    if (_envBinaryPath.isNotEmpty) {
      final envBinaryExists = await File(_envBinaryPath).exists();
      if (envBinaryExists) return _envBinaryPath;
    }
    for (final candidate in _binaryCandidates) {
      final candidateExists = await File(candidate).exists();
      if (candidateExists) return candidate;
    }
    try {
      final lookupCommand = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(lookupCommand, ['llama-server']);
      final output = (result.stdout as String).trim();
      if (result.exitCode == 0 && output.isNotEmpty) {
        return output.split('\n').first.trim();
      }
    } on ProcessException {
      // El comando de búsqueda no existe en esta plataforma; seguir sin PATH.
    }
    return null;
  }
}
