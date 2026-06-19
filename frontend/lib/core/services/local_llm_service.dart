import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_quiz_models.dart';
import 'flutter_gemma_backend.dart';
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

  /// En móvil la inferencia corre on-device vía flutter_gemma (no hay
  /// llama-server). El resto de plataformas usan el motor llama.cpp.
  bool get _useMobileBackend =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
  /// En web no hay filesystem: devuelve false sin lanzar.
  Future<bool> checkModelExists() async {
    if (kIsWeb) return false;
    if (_useMobileBackend) return FlutterGemmaBackend.instance.isInstalled();
    final modelFile = File(await _modelPath);
    final modelFileExists = await modelFile.exists();
    if (!modelFileExists) return false;
    final length = await modelFile.length();
    return length >= _minValidModelBytes;
  }

  /// La IA está disponible si ya hay un motor sano respondiendo (otra
  /// instancia o proceso externo lo levantó — único camino en web) o si el
  /// modelo está descargado y podemos arrancarlo nosotros.
  Future<bool> isAvailable() async {
    if (_useMobileBackend) return FlutterGemmaBackend.instance.isInstalled();
    final engineAlreadyUp = await LlamaServerManager.instance.isHealthy();
    if (engineAlreadyUp) return true;
    return checkModelExists();
  }

  /// Descarga única del modelo Gemma 3 4B QAT Q4_0 (~2.4 GB).
  /// Acción 100% controlada por el usuario y opcional.
  Future<void> downloadModel() async {
    if (_useMobileBackend) {
      await FlutterGemmaBackend.instance.downloadModel(
        onProgress: (p) => downloadProgress.value = p,
        onStatus: (s) => statusNotifier.value = s,
      );
      return;
    }

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
    statusNotifier.value = 'Inicializando IA local en el dispositivo…';

    if (_useMobileBackend) {
      await FlutterGemmaBackend.instance
          .init(onStatus: (s) => statusNotifier.value = s);
      _initialized = true;
      return;
    }

    // Si otra instancia (u otro proceso) ya dejó el motor sano con el modelo
    // cargado, reutilizarlo sin tocar disco.
    final engineAlreadyUp = await LlamaServerManager.instance.isHealthy();
    if (engineAlreadyUp) {
      _initialized = true;
      statusNotifier.value = 'IA lista offline.';
      return;
    }

    final exists = await checkModelExists();
    if (!exists) {
      throw StateError('El modelo de IA local no está descargado.');
    }

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
    if (!_useMobileBackend && !LlamaServerManager.instance.isSupportedPlatform) {
      return;
    }
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
  }) async {
    const depthInstruction = 'Las preguntas deben ser de comprensión directa y clara, '
        'pero ricas en contenido: evalúa el significado literal, así como aspectos prácticos, '
        'implicaciones espirituales o doctrina clave de forma accesible. '
        'Los distractores deben ser opciones plausibles pero claramente incorrectas para quien '
        'comprenda bien el versículo.';

    final prompt = 'Eres un generador de cuestionarios en español para una app de memorización de versículos bíblicos.\n'
        'Texto a evaluar ($reference): "$verseText"\n\n'
        'Genera exactamente:\n'
        '1. "trueFalse": una afirmación sobre el contenido del texto con su veredicto "isTrue". '
        'Decide al azar si la haces verdadera o falsa; si es falsa, introduce un error sutil.\n'
        '2. "multipleChoice": una pregunta con "correct" (respuesta correcta) y "distractors" (exactamente 3 incorrectas).\n'
        '3. "openQuestion": una pregunta abierta corta para que el usuario explique el texto con sus palabras.\n\n'
        'IMPORTANTE: Cada una de las 3 secciones (trueFalse, multipleChoice y openQuestion) debe evaluar aspectos, detalles o conceptos COMPLETAMENTE DIFERENTES del texto. Evita a toda costa que pregunten sobre el mismo tema o el mismo detalle para garantizar variedad.\n\n'
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

  static const Map<String, dynamic> _distractorSchema = {
    'type': 'object',
    'properties': {
      'distractors': {
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 1,
        'maxItems': 12,
      },
    },
    'required': ['distractors'],
  };

  /// Genera un pool de palabras-distractoras tramposas (parecidas a las del
  /// versículo) para el ejercicio "Elige la palabra correcta". A diferencia de
  /// elegir otras palabras al azar del texto, la IA propone palabras que
  /// confunden de verdad: sinónimos cercanos, misma familia, errores comunes.
  /// Una sola llamada por tarjeta; el ejercicio reparte el pool entre huecos.
  Future<List<String>> generateCompletionDistractors({
    required String reference,
    required String verseText,
    int count = 8,
  }) async {
    final prompt =
        'Eres un tutor de memorización de versículos en español.\n'
        'Texto ($reference): "$verseText"\n\n'
        'Devuelve "distractors": una lista de exactamente $count PALABRAS sueltas '
        '(una sola palabra cada una, sin frases) que sirvan como opciones '
        'INCORRECTAS pero CONFUSAS para un ejercicio de rellenar huecos del texto. '
        'Deben parecerse a palabras del versículo: sinónimos cercanos, misma '
        'familia, conjugaciones o errores plausibles — nunca palabras que '
        'aparezcan tal cual en el texto. Todo en español. Solo el JSON.';
    final content = await _chat(
      prompt,
      temperature: 0.9,
      maxTokens: 200,
      jsonSchema: _distractorSchema,
    );
    final decoded = _decodeJsonObject(content);
    final raw = (decoded['distractors'] as List?) ?? const [];
    final words = <String>[];
    for (final item in raw) {
      final word = item.toString().trim().split(RegExp(r'\s+')).first;
      if (word.length > 2 && !words.contains(word)) words.add(word);
    }
    return words;
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
        'Criterio de Evaluación:\n'
        '- Sé muy flexible e indulgente: si la respuesta del usuario es básicamente correcta, aproximada o demuestra un entendimiento general/básico, márcala como CORRECTA ("isCorrect": true). No exijas explicaciones exhaustivas o teología profunda.\n'
        '- Si la respuesta está bien pero es muy simple o le falta profundizar, márcala igualmente como CORRECTA ("isCorrect": true), y usa el "feedback" para añadir detalles adicionales o aclaraciones de forma amable e instructiva (envía la profundidad como una aclaración, no como un motivo de fallo).\n'
        '- Solo marca "isCorrect" como false si la respuesta es completamente errónea, vacía o totalmente fuera de tema.\n'
        '- En "feedback" escribe 1 o 2 frases breves y amigables explicando el veredicto o complementando la respuesta.\n'
        'Responde únicamente con el JSON.';

    final content = await _chat(
      prompt,
      temperature: 0.4,
      maxTokens: _evaluationMaxTokens,
      jsonSchema: _openAnswerEvaluationSchema,
    );
    return AiOpenAnswerEvaluation.fromJson(_decodeJsonObject(content));
  }

  static const Map<String, dynamic> _deckSchema = {
    'type': 'object',
    'properties': {
      'cards': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'front': {'type': 'string'},
            'back': {'type': 'string'},
          },
          'required': ['front', 'back'],
        },
        'minItems': 1,
        'maxItems': 30,
      },
    },
    'required': ['cards'],
  };

  /// Genera con la IA local un mazo de tarjetas frente/dorso a partir de un
  /// tema libre (p.ej. "Salmos de consuelo", "Inglés B1: comida", "Fechas de
  /// la Reforma"). Devuelve pares front/back listos para editar. Una sola
  /// llamada; el llamador valida disponibilidad con [isAvailable] antes.
  Future<List<({String front, String back})>> generateCardsFromTopic({
    required String topic,
    int count = 8,
  }) async {
    final n = count.clamp(3, 20);
    final prompt =
        'Eres un generador de tarjetas de memorización (flashcards).\n'
        'Tema: "$topic".\n\n'
        'Genera exactamente $n tarjetas en "cards". Cada tarjeta tiene:\n'
        '- "front": el anverso — una palabra, pregunta o concepto CORTO a recordar.\n'
        '- "back": el reverso — la respuesta, definición o traducción CORTA.\n'
        'Hazlas variadas, correctas y concretas; nada de relleno. Usa el idioma '
        'que el tema sugiera (por defecto español). Responde únicamente con el JSON.';
    final content = await _chat(
      prompt,
      temperature: 0.8,
      maxTokens: 80 + n * 40,
      jsonSchema: _deckSchema,
    );
    final decoded = _decodeJsonObject(content);
    final raw = (decoded['cards'] as List?) ?? const [];
    final cards = <({String front, String back})>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final front = (item['front']?.toString() ?? '').trim();
      final back = (item['back']?.toString() ?? '').trim();
      if (front.isNotEmpty && back.isNotEmpty) {
        cards.add((front: front, back: back));
      }
    }
    return cards;
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

    if (_useMobileBackend) {
      // flutter_gemma no aplica grammar JSON como llama.cpp: el prompt ya pide
      // "responde únicamente con el JSON" y _decodeJsonObject lo sanea.
      return FlutterGemmaBackend.instance.chat(
        prompt,
        temperature: temperature,
        randomSeed: _seedRandom.nextInt(1 << 30),
        onStatus: (s) => statusNotifier.value = s,
      );
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
