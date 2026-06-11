import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_quiz_models.dart';
import 'llama_server_manager.dart';

/// Servicio local offline de inferencia de IA (Gemma 3 4B IT, cuantizado QAT
/// Q4_0 en formato GGUF). Descarga el modelo una sola vez y ejecuta toda la
/// generación de preguntas 100% en el dispositivo vía llama.cpp (Metal/GPU),
/// sin internet y sin datos precocinados: cada set de preguntas sale del
/// modelo en el momento.
class LocalLlmService {
  LocalLlmService._privateConstructor();
  static final LocalLlmService instance = LocalLlmService._privateConstructor();

  // Espejo público (sin gate de licencia) del GGUF QAT oficial de Google.
  static const String _modelUrl =
      'https://huggingface.co/ggml-org/gemma-3-4b-it-qat-GGUF/resolve/main/gemma-3-4b-it-qat-Q4_0.gguf';
  static const String _modelFileName = 'gemma-3-4b-it-qat-Q4_0.gguf';
  static const String _legacyModelFileName = 'gemma-2b-it-gpu-int4.bin';
  static const int _minValidModelBytes = 2000 * 1024 * 1024;
  static const Duration _generationTimeout = Duration(minutes: 3);
  static const double _quizTemperature = 1.0;
  static const int _quizMaxTokens = 900;
  static const int _evaluationMaxTokens = 300;

  static const Map<String, dynamic> _quizRoundSetSchema = {
    'type': 'object',
    'properties': {
      'trueFalse': {
        'type': 'object',
        'properties': {
          'statement': {'type': 'string'},
          'isTrue': {'type': 'boolean'},
        },
        'required': ['statement', 'isTrue'],
      },
      'multipleChoice': {
        'type': 'object',
        'properties': {
          'question': {'type': 'string'},
          'correct': {'type': 'string'},
          'distractors': {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 3,
            'maxItems': 3,
          },
        },
        'required': ['question', 'correct', 'distractors'],
      },
      'openQuestion': {
        'type': 'object',
        'properties': {
          'question': {'type': 'string'},
        },
        'required': ['question'],
      },
    },
    'required': ['trueFalse', 'multipleChoice', 'openQuestion'],
  };

  static const Map<String, dynamic> _openAnswerEvaluationSchema = {
    'type': 'object',
    'properties': {
      'isCorrect': {'type': 'boolean'},
      'feedback': {'type': 'string'},
    },
    'required': ['isCorrect', 'feedback'],
  };

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: _generationTimeout,
  ));
  final math.Random _seedRandom = math.Random();

  bool _initialized = false;
  Future<void>? _initInFlight;
  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  bool get isReady => _initialized;

  Future<Directory> get _llmDirectory async {
    final docDir = await getApplicationSupportDirectory();
    final llmDir = Directory('${docDir.path}/local_llm');
    final llmDirExists = await llmDir.exists();
    if (!llmDirExists) {
      await llmDir.create(recursive: true);
    }
    return llmDir;
  }

  Future<String> get _modelPath async {
    final dir = await _llmDirectory;
    return '${dir.path}/$_modelFileName';
  }

  /// Comprueba si el modelo cuantizado ya está descargado y completo.
  Future<bool> checkModelExists() async {
    final modelFile = File(await _modelPath);
    final modelFileExists = await modelFile.exists();
    if (!modelFileExists) return false;
    final length = await modelFile.length();
    return length >= _minValidModelBytes;
  }

  /// Descarga única del modelo Gemma 3 4B QAT Q4_0 (~2.4 GB).
  /// Acción 100% controlada por el usuario y opcional.
  Future<void> downloadModel() async {
    final savePath = await _modelPath;

    final alreadyDownloaded = await checkModelExists();
    if (alreadyDownloaded) {
      downloadProgress.value = 1.0;
      statusNotifier.value = 'Modelo listo.';
      return;
    }

    statusNotifier.value = 'Iniciando descarga de Gemma 3 4B (QAT Q4_0)…';
    downloadProgress.value = 0.0;

    try {
      await _dio.download(
        _modelUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            downloadProgress.value = progress;
            final percent = (progress * 100).round();
            statusNotifier.value = 'Descargando modelo local: $percent%';
          }
        },
      );

      downloadProgress.value = 1.0;
      statusNotifier.value = 'Descarga de IA completada con éxito.';
      await _deleteLegacyModel();
    } catch (e) {
      statusNotifier.value = 'Error al descargar modelo local de IA.';
      debugPrint('Error downloading LLM model: $e');
      rethrow;
    }
  }

  /// El modelo Gemma 2 antiguo ya no se usa; liberar sus ~1.4 GB.
  Future<void> _deleteLegacyModel() async {
    final dir = await _llmDirectory;
    final legacyFile = File('${dir.path}/$_legacyModelFileName');
    final legacyExists = await legacyFile.exists();
    if (legacyExists) {
      await legacyFile.delete();
      debugPrint('Modelo legado Gemma 2 eliminado.');
    }
  }

  /// Levanta (o reutiliza) el motor llama.cpp con el modelo cargado.
  Future<void> initLlm() {
    if (_initialized) return Future.value();
    return _initInFlight ??= _doInit().whenComplete(() {
      _initInFlight = null;
    });
  }

  Future<void> _doInit() async {
    final exists = await checkModelExists();
    if (!exists) {
      throw StateError('El modelo de IA local no está descargado.');
    }

    statusNotifier.value = 'Inicializando IA local en el dispositivo…';
    try {
      final modelPath = await _modelPath;
      await LlamaServerManager.instance.ensureRunning(
        modelPath,
        onStatus: (status) => statusNotifier.value = status,
      );
      _initialized = true;
      statusNotifier.value = 'IA lista offline.';
      debugPrint('Local LLM listo sirviendo: $modelPath');
    } catch (e) {
      statusNotifier.value = 'Error al inicializar IA local.';
      debugPrint('Error initializing local LLM: $e');
      rethrow;
    }
  }

  /// Calienta el motor en segundo plano al arrancar la app si el modelo ya
  /// está descargado, para que el primer quiz no espere la carga del modelo.
  Future<void> warmUpIfModelReady() async {
    if (!LlamaServerManager.instance.isSupportedPlatform) return;
    try {
      final exists = await checkModelExists();
      if (!exists) return;
      await initLlm();
    } catch (e) {
      debugPrint('Warm-up de IA local falló (no bloqueante): $e');
    }
  }

  /// Genera un set completo de preguntas (V/F, opción múltiple y respuesta
  /// abierta) sobre el versículo dado. Cada llamada produce preguntas nuevas.
  Future<AiQuizRoundSet> generateQuizRoundSet({
    required String reference,
    required String verseText,
    required bool advanced,
  }) async {
    final depthInstruction = advanced
        ? 'Las preguntas deben ser de análisis teológico profundo: doctrina, '
            'contexto histórico, implicaciones espirituales y aplicación práctica. '
            'Los distractores deben ser errores teológicos sutiles pero claramente incorrectos.'
        : 'Las preguntas deben ser simples y directas, centradas en comprender '
            'el contenido del texto. Los distractores deben ser plausibles pero claramente incorrectos.';

    final prompt = 'Eres un generador de cuestionarios en español para una app de memorización de versículos bíblicos.\n'
        'Texto a evaluar ($reference): "$verseText"\n\n'
        'Genera exactamente:\n'
        '1. "trueFalse": una afirmación sobre el contenido del texto con su veredicto "isTrue". '
        'Decide al azar si la haces verdadera o falsa; si es falsa, introduce un error sutil.\n'
        '2. "multipleChoice": una pregunta con "correct" (respuesta correcta) y "distractors" (exactamente 3 incorrectas).\n'
        '3. "openQuestion": una pregunta abierta corta para que el usuario explique el texto con sus palabras.\n\n'
        '$depthInstruction\n'
        'Todo en español. Responde únicamente con el JSON.';

    final content = await _chat(
      prompt,
      temperature: _quizTemperature,
      maxTokens: _quizMaxTokens,
      jsonSchema: _quizRoundSetSchema,
    );
    return AiQuizRoundSet.fromJson(_decodeJsonObject(content));
  }

  /// Evalúa con la IA local la respuesta libre del usuario a una pregunta
  /// abierta sobre el versículo. Devuelve veredicto y feedback breve.
  Future<AiOpenAnswerEvaluation> evaluateOpenAnswer({
    required String question,
    required String verseText,
    required String userAnswer,
  }) async {
    final prompt = 'Eres un tutor de memorización bíblica. Evalúa en español la respuesta del usuario.\n'
        'Texto de referencia: "$verseText"\n'
        'Pregunta abierta: "$question"\n'
        'Respuesta del usuario: "${userAnswer.trim()}"\n\n'
        'Marca "isCorrect" como true solo si la respuesta demuestra comprensión real del texto '
        '(aunque esté escrita con sus propias palabras). Una respuesta vacía de contenido, '
        'fuera de tema o sin relación con el texto es incorrecta.\n'
        'En "feedback" escribe 1 o 2 frases breves, cálidas y concretas explicando el veredicto.\n'
        'Responde únicamente con el JSON.';

    final content = await _chat(
      prompt,
      temperature: 0.4,
      maxTokens: _evaluationMaxTokens,
      jsonSchema: _openAnswerEvaluationSchema,
    );
    return AiOpenAnswerEvaluation.fromJson(_decodeJsonObject(content));
  }

  /// Inferencia base contra el servidor llama.cpp local (API OpenAI-compatible).
  Future<String> _chat(
    String prompt, {
    required double temperature,
    required int maxTokens,
    Map<String, dynamic>? jsonSchema,
  }) async {
    if (!_initialized) {
      await initLlm();
    }

    final baseUrl = LlamaServerManager.instance.baseUrl;
    final response = await _dio.post(
      '$baseUrl/v1/chat/completions',
      data: {
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
        'seed': _seedRandom.nextInt(1 << 30),
        if (jsonSchema != null)
          'response_format': {
            'type': 'json_object',
            'schema': jsonSchema,
          },
      },
    );

    final content =
        response.data['choices'][0]['message']['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw StateError('La IA local devolvió una respuesta vacía.');
    }
    return content.trim();
  }

  Map<String, dynamic> _decodeJsonObject(String content) {
    // La gramática de llama.cpp permite saltos de línea crudos dentro de
    // strings JSON; jsonDecode los rechaza. Normalizarlos a espacios es
    // inocuo fuera de strings y repara el JSON dentro de ellas.
    final sanitized = content.replaceAll(RegExp(r'[\x00-\x1F]'), ' ');
    final decoded = jsonDecode(sanitized);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('La IA local no devolvió un objeto JSON.');
  }
}
