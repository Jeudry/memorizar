import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_quiz_models.dart';
import 'flutter_gemma_backend.dart';
import 'llama_server_manager.dart';

/// Servicio local offline de inferencia de IA (Gemma 4 E2B IT, cuantizado QAT
/// Q2_K en formato GGUF). Descarga el modelo una sola vez y ejecuta toda la
/// generación de preguntas 100% en el dispositivo vía llama.cpp (Metal/GPU),
/// sin internet y sin datos precocinados: cada set de preguntas sale del
/// modelo en el momento.
class LocalLlmService {
  LocalLlmService._privateConstructor();
  static final LocalLlmService instance = LocalLlmService._privateConstructor();

  // Gemma 4 E2B QAT GGUF con cuantización Q2_K por bartowski para uso móvil.
  static const String _modelUrl =
      'https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/google_gemma-4-E2B-it-Q2_K.gguf';
  static const String _modelFileName = 'google_gemma-4-E2B-it-Q2_K.gguf';
  static const String _legacyModelFileName = 'gemma-3-4b-it-qat-Q4_0.gguf';
  static const int _minValidModelBytes = 3000 * 1024 * 1024; // 3.02 GB
  static const Duration _generationTimeout = Duration(minutes: 3);
  static const double _quizTemperature = 1.0;
  static const int _quizMaxTokens = 900;

  /// Reintentos de la generación del quiz ante un JSON irrecuperable del modelo
  /// on-device. Cada generación tarda ~20s, así que el normalizador tolerante
  /// hace el trabajo pesado y esto sólo cubre fallos extremos; mantenerlo bajo.
  static const int _quizMaxAttempts = 2;
  static const int _evaluationMaxTokens = 300;

  /// Reintentos de la evaluación de respuesta abierta ante un JSON malformado
  /// del modelo on-device (cada intento re-genera con nueva semilla).
  static const int _evaluationMaxAttempts = 3;

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

  static const Map<String, dynamic> _intruderVerseSchema = {
    'type': 'object',
    'properties': {
      'alteredVerse': {'type': 'string'},
      'intruderWords': {
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 1,
        'maxItems': 3,
      },
      'explanation': {'type': 'string'},
    },
    'required': ['alteredVerse', 'intruderWords', 'explanation'],
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
  bool _isMockFallback = false;

  bool get isReady => _initialized;
  bool get isMockFallback => _isMockFallback;

  String get modelDescription {
    if (_isMockFallback) {
      return 'IA Simulada (Modo Desarrollo)';
    }
    if (_useMobileBackend) {
      return 'Gemma 4 E2B LiteRT (~2.58 GB)';
    } else {
      return 'Gemma 4 E2B Q2 QAT (~3.02 GB)';
    }
  }

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

  /// La IA está disponible si el modelo está descargado localmente
  /// (o si estamos en web y ya hay un motor sano respondiendo).
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      return LlamaServerManager.instance.isHealthy();
    }
    if (_useMobileBackend) return FlutterGemmaBackend.instance.isInstalled();
    final modelExists = await checkModelExists();
    if (!modelExists) {
      // Si el archivo no existe localmente en escritorio, nos aseguramos de apagar
      // cualquier proceso huérfano para evitar falsos positivos de salud.
      await LlamaServerManager.instance.stop();
      return false;
    }
    return true;
  }

  /// Descarga única del modelo Gemma 4 E2B QAT Q2_K (~3.0 GB).
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

    statusNotifier.value = 'Iniciando descarga de Gemma 4 E2B (QAT Q2_K)…';
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

  /// Elimina físicamente el archivo del modelo activo actual y limpia el estado para forzar re-descarga.
  Future<String> deleteModelFile() async {
    _initialized = false;
    // Si el servidor local está corriendo, lo detenemos para poder borrar el archivo sin bloqueos
    await LlamaServerManager.instance.ensureRunning('');
    final path = await _modelPath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    downloadProgress.value = 0.0;
    statusNotifier.value = 'Modelo eliminado localmente.';
    return path;
  }

  /// El modelo Gemma 3 antiguo ya no se usa; liberar sus ~2.4 GB.
  Future<void> _deleteLegacyModel() async {
    final dir = await _llmDirectory;
    final legacyFile = File('${dir.path}/$_legacyModelFileName');
    final legacyExists = await legacyFile.exists();
    if (legacyExists) {
      await legacyFile.delete();
      debugPrint('Modelo legado Gemma 3 eliminado.');
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
      // La PRIMERA carga del modelo a GPU en un dispositivo real tarda bastante
      // más que unos pocos segundos. En iOS de desarrollo (simulador) no hay
      // modelo GPU, así que un timeout corto deja caer a IA simulada; en un
      // dispositivo real (Android) hay que ESPERAR la carga real: abortarla a
      // los 4s era justo lo que hacía fallar la generación en el PRIMER intento
      // (la carga nativa seguía en background y el segundo intento ya la tomaba
      // caliente). Por eso el timeout aquí es generoso fuera del simulador iOS.
      final useSimulatorFallback = !kIsWeb && Platform.isIOS;
      final initTimeout = useSimulatorFallback
          ? const Duration(seconds: 4)
          : const Duration(seconds: 120);
      try {
        await FlutterGemmaBackend.instance
            .init(onStatus: (s) => statusNotifier.value = s)
            .timeout(initTimeout);
        _initialized = true;
        _isMockFallback = false;
      } catch (e) {
        debugPrint('Fallo al inicializar Gemma nativo ($e).');
        if (useSimulatorFallback) {
          debugPrint('Activando fallback de IA simulada para desarrollo (Simulador iOS).');
          _initialized = true;
          _isMockFallback = true;
          statusNotifier.value = 'IA Simulada (Modo Simulador)';
        } else {
          rethrow;
        }
      }
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
  /// abierta) sobre uno o varios versículos. Cuando se pasa más de un texto, las
  /// 3 preguntas se reparten entre ellos: se combinan en una sola pregunta donde
  /// tenga sentido y, si no, cada una de las 3 secciones se dedica a un texto
  /// distinto, de modo que el conjunto cubra todos los textos del grupo. Cada
  /// llamada produce preguntas nuevas.
  Future<AiQuizRoundSet> generateQuizRoundSet({
    required List<({String reference, String verseText})> verses,
  }) async {
    assert(verses.isNotEmpty, 'Se requiere al menos un versículo.');
    const depthInstruction = 'Las preguntas y respuestas deben ser CORTAS, SIMPLES y directas: '
        'lenguaje sencillo y cotidiano, UNA sola idea por pregunta, frases breves '
        '(idealmente menos de 15 palabras). Evita enunciados largos, rebuscados o con varias '
        'cláusulas, y términos teológicos complicados. Pregunta por el sentido literal y evidente '
        'del texto. Los distractores deben ser cortos, plausibles pero claramente incorrectos para '
        'quien comprenda el versículo.';

    final isMulti = verses.length > 1;

    final String textBlock;
    final String coverageInstruction;
    if (isMulti) {
      final buffer = StringBuffer();
      for (var i = 0; i < verses.length; i++) {
        buffer.writeln('${i + 1}. (${verses[i].reference}): "${verses[i].verseText}"');
      }
      textBlock = 'Textos a evaluar (${verses.length}):\n${buffer.toString().trimRight()}';
      coverageInstruction =
          'Hay ${verses.length} textos. Devuelve UN ÚNICO objeto JSON con SOLO 3 preguntas en total '
          '(una en "trueFalse", una en "multipleChoice" y una en "openQuestion"). NO devuelvas un '
          'array ni una lista, y NO generes un set de preguntas por cada texto. Reparte esas 3 '
          'preguntas entre los textos: dedica preferentemente cada una a un texto DISTINTO '
          '(combinándolos en una sola pregunta si tiene sentido), de modo que en conjunto cubran '
          'todos los textos del grupo.';
    } else {
      textBlock = 'Texto a evaluar (${verses.first.reference}): "${verses.first.verseText}"';
      coverageInstruction =
          'Devuelve UN ÚNICO objeto JSON. Cada una de las 3 secciones (trueFalse, multipleChoice y '
          'openQuestion) debe evaluar aspectos, detalles o conceptos COMPLETAMENTE DIFERENTES del '
          'texto. Evita a toda costa que pregunten sobre el mismo tema o el mismo detalle.';
    }

    // El modelo on-device a veces ignora la estructura (devuelve un array, JSON
    // truncado o malformado) en una generación concreta; re-rolamos unas pocas
    // veces antes de propagar el error a la UI.
    Object? lastError;
    for (var attempt = 1; attempt <= _quizMaxAttempts; attempt++) {
      final entropy = _seedRandom.nextInt(100000);
      final prompt = 'Eres un generador de cuestionarios en español para una app de memorización de versículos bíblicos.\n'
          'Semilla de variación aleatoria: $entropy\n'
          '$textBlock\n\n'
          'Genera exactamente:\n'
          '1. "trueFalse": una afirmación CORTA y simple sobre el contenido del texto con su veredicto "isTrue". '
          'Decide al azar si la haces verdadera o falsa; si es falsa, introduce un error sutil.\n'
          '2. "multipleChoice": una pregunta CORTA con "correct" (respuesta correcta y breve) y "distractors" (exactamente 3 incorrectas y breves).\n'
          '3. "openQuestion": una pregunta abierta CORTA y sencilla para que el usuario explique el texto con sus palabras.\n\n'
          'IMPORTANTE: $coverageInstruction\n\n'
          '$depthInstruction\n'
          'Formato de salida OBLIGATORIO: un ÚNICO objeto JSON EXACTAMENTE con esta forma '
          '(sin envolturas, sin la clave "questions", sin arrays/listas):\n'
          '{"trueFalse":{"statement":"...","isTrue":true},"multipleChoice":{"question":"...","correct":"...","distractors":["...","...","..."]},"openQuestion":{"question":"..."}}\n'
          'Todo en español. Responde únicamente con el JSON, sin texto adicional.';
      try {
        final content = await _chat(
          prompt,
          temperature: _quizTemperature,
          maxTokens: _quizMaxTokens,
          jsonSchema: _quizRoundSetSchema,
        );
        debugPrint('=== RESPUESTA IA LOCAL QUIZ CRUDA (intento $attempt) ===\n$content\n=====================================');
        return _parseQuizRoundSet(content);
      } catch (e) {
        lastError = e;
        debugPrint('Generación de quiz falló (intento $attempt/$_quizMaxAttempts): $e');
      }
    }
    throw StateError('No se pudo generar el quiz tras $_quizMaxAttempts intentos: $lastError');
  }

  /// Parsea la respuesta del quiz con el normalizador tolerante: acepta el
  /// objeto esperado, un array de sets, `{questions:[...]}` o un array de
  /// preguntas tipadas, con nombres de campo variables.
  AiQuizRoundSet _parseQuizRoundSet(String content) {
    return AiQuizRoundSet.lenient(_decodeJsonStructure(content));
  }

  /// Genera un versículo alterado con palabras intrusas según el nivel de dificultad:
  /// - Nivel 1: Cambia exactamente 1 palabra. Error obvio o sinónimo simple.
  /// - Nivel 2: Cambia exactamente 2 palabras. Sinónimos sutiles o palabras parecidas.
  /// - Nivel 3: Cambia exactamente 3 palabras. Conectores sutiles o teología ligeramente alterada de forma casi imperceptible.
  Future<IntruderVerseSet> generateIntruderVerse({
    required String reference,
    required String verseText,
    required int level,
  }) async {
    String levelInstruction = '';
    if (level == 1) {
      levelInstruction = 'Reemplaza exactamente 1 palabra del versículo por una palabra incorrecta (un "intruso"). '
          'La alteración debe ser sutil y plausible (no obvia), como un sinónimo cercano o una palabra que encaje en el contexto gramatical pero cambie el significado sutilmente.';
    } else if (level == 2) {
      levelInstruction = 'Reemplaza exactamente 2 palabras del versículo por dos palabras incorrectas ("intrusos"). '
          'Las alteraciones deben ser de dificultad alta y muy parecidas a las originales (longitud similar, letras similares, raíces compartidas o sinónimos extremadamente cercanos) que se confundan fácilmente al leer rápido.';
    } else {
      levelInstruction = 'Reemplaza exactamente 3 palabras del versículo por tres palabras incorrectas ("intrusos"). '
          'Las alteraciones deben ser sumamente difíciles de identificar a simple vista: cambia conectores gramaticales pequeños (ej: "por" en vez de "para", "con" en vez de "en"), o palabras con un significado teológico casi idéntico pero incorrecto (ej: "Señor" en vez de "Dios" si el original decía Dios).';
    }


    final entropy = _seedRandom.nextInt(100000);
    final prompt = 'Eres un creador de desafíos premium de memorización de la Biblia en español.\n'
        'Semilla de variación aleatoria: $entropy\n'
        'Tu tarea es tomar el versículo indicado y generar una versión alterada del mismo.\n\n'
        'Versículo original ($reference): "$verseText"\n\n'
        'Instrucciones específicas:\n'
        '- $levelInstruction\n'
        '- Las palabras intrusas nuevas no deben existir en el versículo original en esa misma posición.\n'
        '- El resto de palabras del versículo deben permanecer idénticas al original.\n'
        '- Devuelve exactamente en "alteredVerse" el versículo modificado completo conservando signos de puntuación originales donde sea posible.\n'
        '- Devuelve exactamente en "intruderWords" la lista de las palabras intrusas (tal y como aparecen en el versículo alterado, sin puntuación pegada si es posible).\n'
        '- Devuelve en "explanation" una explicación interactiva de alta calidad que indique qué palabras se cambiaron y por qué el texto original usa esas palabras (con un matiz teológico o lingüístico interesante).\n\n'
        'Responde únicamente con el objeto JSON estructurado. Todo en español.';

    final content = await _chat(
      prompt,
      temperature: 0.8,
      maxTokens: 600,
      jsonSchema: _intruderVerseSchema,
    );

    return IntruderVerseSet.fromJson(_decodeJsonObject(content));
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
    final entropy = _seedRandom.nextInt(100000);
    final prompt =
        'Eres un tutor de memorización de versículos en español.\n'
        'Semilla de variación aleatoria: $entropy\n'
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
    // El modelo on-device a veces emite un JSON malformado o truncado en una
    // generación concreta; un simple re-roll suele resolverlo. Reintentamos
    // unas pocas veces antes de propagar el error a la UI.
    Object? lastError;
    for (var attempt = 1; attempt <= _evaluationMaxAttempts; attempt++) {
      try {
        final entropy = _seedRandom.nextInt(100000);
        final prompt = 'Eres un evaluador de respuestas de cuestionarios de memorización bíblica. Evalúa de forma estricta y lógica la respuesta del usuario.\n'
            'Semilla de variación aleatoria: $entropy\n'
            'Texto de referencia del versículo: "$verseText"\n'
            'Pregunta abierta: "$question"\n'
            'Respuesta del usuario: "${userAnswer.trim()}"\n\n'
            'Instrucciones de Evaluación:\n'
            '1. La respuesta del usuario DEBE estar directamente relacionada con la pregunta y el versículo de referencia. Si el usuario habla de deportes, fútbol, comida, películas, o responde con frases vacías, de evasión o incoherencias, debes responder "isCorrect": false.\n'
            '2. Si la respuesta es relevante y demuestra que el usuario entendió el mensaje del versículo (aunque la explicación sea sencilla, corta o informal), responde "isCorrect": true.\n'
            '3. En "feedback" escribe una frase corta explicando lógicamente por qué es correcta o por qué es incorrecta.\n'
            'Formato de salida OBLIGATORIO: un ÚNICO objeto JSON EXACTAMENTE con esta forma '
            '(sin envolturas ni texto adicional):\n'
            '{"isCorrect":true,"feedback":"..."}\n'
            'Responde únicamente con el JSON.';

        final content = await _chat(
          prompt,
          temperature: 0.4,
          maxTokens: _evaluationMaxTokens,
          jsonSchema: _openAnswerEvaluationSchema,
        );
        debugPrint('=== RESPUESTA IA EVALUACION CRUDA (intento $attempt) ===\n$content\n=====================================');
        final decoded = _decodeJsonStructure(content);
        debugPrint('=== RESPUESTA IA EVALUACION DECODIFICADA ===\n$decoded\n=====================================');
        return AiOpenAnswerEvaluation.lenient(decoded);
      } catch (e) {
        lastError = e;
        debugPrint('Evaluación de respuesta abierta falló (intento $attempt/$_evaluationMaxAttempts): $e');
      }
    }
    throw StateError('No se pudo evaluar la respuesta tras $_evaluationMaxAttempts intentos: $lastError');
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
    final entropy = _seedRandom.nextInt(100000);
    final prompt =
        'Eres un generador de tarjetas de memorización (flashcards).\n'
        'Semilla de variación aleatoria: $entropy\n'
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

    if (_isMockFallback) {
      return _generateMockFallbackResponse(prompt, jsonSchema);
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

  /// Decodifica la respuesta del modelo tolerando que sea un objeto `{...}` o un
  /// array `[...]`. Recorta a la primera estructura JSON (la que abra primero) y
  /// sanea saltos de línea crudos. Devuelve el `Map` o `List` decodificado.
  dynamic _decodeJsonStructure(String content) {
    var cleaned = content.trim();
    // Quitar envoltura markdown (```json ... ```).
    cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();

    final firstObj = cleaned.indexOf('{');
    final firstArr = cleaned.indexOf('[');
    final bool asArray =
        firstArr != -1 && (firstObj == -1 || firstArr < firstObj);
    final start = asArray ? firstArr : firstObj;
    if (start != -1) {
      final end = cleaned.lastIndexOf(asArray ? ']' : '}');
      if (end > start) {
        cleaned = cleaned.substring(start, end + 1);
      }
    }

    final sanitized = cleaned.replaceAll(RegExp(r'[\x00-\x1F]'), ' ');
    return jsonDecode(sanitized);
  }

  Map<String, dynamic> _decodeJsonObject(String content) {
    var cleaned = content.trim();

    // Extraer el objeto JSON buscando el primer '{' y el último '}'
    // Esto limpia cualquier markdown block wrapper (```json ... ```) u otro texto extra.
    final startIdx = cleaned.indexOf('{');
    final endIdx = cleaned.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    // La gramática de llama.cpp permite saltos de línea crudos dentro de
    // strings JSON; jsonDecode los rechaza. Normalizarlos a espacios es
    // inocuo fuera de strings y repara el JSON dentro de ellas.
    final sanitized = cleaned.replaceAll(RegExp(r'[\x00-\x1F]'), ' ');
    final decoded = jsonDecode(sanitized);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('La IA local no devolvió un objeto JSON.');
  }

  String _generateMockFallbackResponse(String prompt, Map<String, dynamic>? jsonSchema) {
    if (jsonSchema == null) return '{}';

    // 1. Quiz Round Set
    if (jsonSchema == _quizRoundSetSchema) {
      return '''
      {
        "trueFalse": {
          "statement": "El versículo enseña la importancia de confiar en Dios en medio de cualquier circunstancia.",
          "isTrue": true
        },
        "multipleChoice": {
          "question": "¿Cuál es la enseñanza central reflejada en este texto?",
          "correct": "La providencia divina y la fidelidad eterna de Dios.",
          "distractors": [
            "La necesidad de acumular riquezas materiales.",
            "El aislamiento absoluto del mundo exterior.",
            "La búsqueda del éxito personal sobre el servicio a los demás."
          ]
        },
        "openQuestion": {
          "question": "¿Cómo aplicarías este versículo en tu vida cotidiana?"
        }
      }
      ''';
    }

    // 2. Intruder Verse
    if (jsonSchema == _intruderVerseSchema) {
      String verseText = "En el principio creó Dios los cielos y la tierra.";
      final match = RegExp(r'Texto \([^)]+\):\s*"([^"]+)"').firstMatch(prompt);
      if (match != null) {
        verseText = match.group(1) ?? verseText;
      }
      final words = verseText.split(' ');
      List<String> intruders = [];
      String altered = verseText;
      if (words.length > 4) {
        if (prompt.contains('1 palabra') || prompt.contains('Nivel 1')) {
          intruders = ['creó'];
          altered = verseText.replaceAll('creó', 'estableció');
        } else if (prompt.contains('2 palabras') || prompt.contains('Nivel 2')) {
          intruders = ['creó', 'tierra'];
          altered = verseText.replaceAll('creó', 'estableció').replaceAll('tierra', 'luna');
        } else {
          intruders = ['creó', 'cielos', 'tierra'];
          altered = verseText.replaceAll('creó', 'estableció').replaceAll('cielos', 'mundos').replaceAll('tierra', 'luna');
        }
      } else {
        intruders = ['incorrecto'];
        altered = '\$verseText (alterado)';
      }
      return '''
      {
        "alteredVerse": "$altered",
        "intruderWords": ${jsonEncode(intruders)},
        "explanation": "Simulación: Se cambiaron palabras clave para evaluar la memorización del versículo."
      }
      ''';
    }

    // 3. Distractor Schema
    if (jsonSchema == _distractorSchema) {
      return '''
      {
        "distractors": ["amor", "paz", "justicia", "verdad", "esperanza", "fe", "gracia", "vida"]
      }
      ''';
    }

    // 4. Open Answer Evaluation
    if (jsonSchema == _openAnswerEvaluationSchema) {
      return '''
      {
        "isCorrect": true,
        "feedback": "Excelente reflexión. Tu respuesta capta muy bien la esencia espiritual y el contexto doctrinal del versículo."
      }
      ''';
    }

    // 5. Deck Schema (Flashcards)
    if (jsonSchema == _deckSchema) {
      return '''
      {
        "cards": [
          {"front": "Fe", "back": "La certeza de lo que se espera, la convicción de lo que no se ve (Hebreos 11:1)."},
          {"front": "Amor", "back": "El vínculo perfecto y el cumplimiento de la ley."},
          {"front": "Gracia", "back": "Favor inmerecido otorgado por Dios."}
        ]
      }
      ''';
    }

    return '{}';
  }
}
