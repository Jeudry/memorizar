import 'dart:async';
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
  static const Duration _generationTimeout = Duration(minutes: 3);
  // 0.9: prioriza la variedad (con la rotación de estilo/enfoque) manteniéndose
  // por debajo del 1.0 que inventaba hechos y degeneraba.
  static const double _quizTemperature = 0.9;
  static const int _quizMaxTokens = 900;

  /// Estilo del cuestionario, elegido al azar por generación para que no se
  /// sienta repetitivo. ~1 de cada 3 sale con trampa sutil (pero justa).
  static const List<String> _quizStyles = [
    'Estilo: directas y claras.',
    'Estilo: directas y claras.',
    'Estilo: ASTUTO — ponle una trampa sutil pero JUSTA: el enunciado falso lleva un error fino y '
        'los distractores son muy plausibles; aun así la respuesta correcta debe poder verificarse con el texto.',
  ];

  /// Enfoque del que parte cada pregunta, rotado al azar para dar variedad y que
  /// no pregunten siempre lo mismo.
  static const List<String> _quizFocusAngles = [
    'el sujeto: quién realiza la acción',
    'la acción principal o el verbo',
    'una palabra o detalle concreto del texto',
    'el lugar, el tiempo o el contexto',
    'el orden o la secuencia de lo que ocurre',
    'el propósito, la causa o la consecuencia',
    'lo que el texto afirma o niega explícitamente',
  ];

  /// Reintentos de la generación del quiz ante un JSON irrecuperable del modelo
  /// on-device. Cada generación tarda ~20s, así que el normalizador tolerante
  /// hace el trabajo pesado y esto sólo cubre fallos extremos; mantenerlo bajo.
  static const int _quizMaxAttempts = 2;
  // El veredicto es un JSON diminuto ({isCorrect, feedback corto}); acotar los
  // tokens hace cada intento MUCHO más rápido (evita generación larga inútil).
  static const int _evaluationMaxTokens = 128;

  /// Ejemplo de FORMATO para el enunciado de verdadero/falso. Debe ser NEUTRAL
  /// (no una verdad de ningún versículo real): el modelo pequeño tiende a copiar
  /// el ejemplo verbatim, y si fuera contenido bíblico real lo pegaría como
  /// respuesta con la etiqueta isTrue a la suerte (bug: marcaba FALSO una
  /// afirmación verdadera del versículo).
  static const String _tfFormatExample =
      'El mensajero llegó al pueblo al amanecer.';

  /// Reintentos de la evaluación de respuesta abierta. Con los tokens acotados
  /// cada intento es rápido, así que damos 3 oportunidades (el fallo típico es
  /// una respuesta vacía transitoria que un re-roll resuelve) sin que la espera
  /// total se vuelva eterna.
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
    },
    'required': ['alteredVerse', 'intruderWords'],
  };


  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: _generationTimeout,
  ));
  final math.Random _seedRandom = math.Random();

  /// Serializa la inferencia: el motor on-device (libLiteRtLm) crashea
  /// (SIGSEGV en su ThreadPool) si se le piden dos inferencias a la vez. Encadena
  /// las llamadas para que SIEMPRE corra una sola — esto también permite
  /// pre-generar en segundo plano sin chocar con una generación en curso.
  Future<void> _inferenceChain = Future.value();

  // Apagado por inactividad: el motor (llama-server ~2 GB en desktop, o el
  // modelo Gemma on-device en móvil) se libera tras un rato sin inferencias y
  // se re-levanta on-demand. Clave para no comer RAM, sobre todo en móvil.
  Timer? _idleTimer;
  int _pendingInferences = 0;
  static const Duration _idleUnloadTimeout = Duration(seconds: 120);

  // Mientras se captura/transcribe voz (Whisper en CPU), pausamos el prefetch
  // de IA local para no pelear por la CPU: si no, el "Evaluando audio…" se
  // eterniza porque el decode de Whisper queda hambriento. El prefetch se
  // reanuda solo en el siguiente rebuild cuando esto vuelve a false.
  bool _voiceCaptureActive = false;
  bool get voiceCaptureActive => _voiceCaptureActive;
  void setVoiceCaptureActive(bool active) => _voiceCaptureActive = active;

  // Los ejercicios con IA son una función PREMIUM. Sin premium NO se levanta el
  // motor ni se hace ninguna inferencia (los ejercicios usan sus fallbacks
  // locales/código). Lo sincroniza el store al cargar/cambiar el estado premium.
  bool _premiumUnlocked = false;
  bool get premiumUnlocked => _premiumUnlocked;
  /// Notifica cambios del gate premium para que los ejercicios en curso que
  /// cayeron al fallback re-intenten la IA cuando se activa premium a mitad de
  /// sesión (y para que el prefetch arranque desde ese punto).
  final ValueNotifier<bool> premiumNotifier = ValueNotifier<bool>(false);
  void setPremiumUnlocked(bool value) {
    if (_premiumUnlocked == value) return;
    _premiumUnlocked = value;
    premiumNotifier.value = value;
    if (value) {
      // Premium recién activado: calienta el motor para que el prefetch y los
      // ejercicios de IA arranquen de inmediato desde este punto.
      unawaited(warmUpIfModelReady());
    } else {
      // Si se pierde premium, apaga el motor para no retener RAM.
      unawaited(unloadForIdle());
    }
  }

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

  /// Comprueba si el modelo ya está descargado y completo. No usamos el peso
  /// (frágil): el archivo final solo existe cuando la descarga terminó (se baja
  /// a un `.part` y se renombra atómicamente al final), y validamos que sea un
  /// GGUF real por su cabecera mágica. En web no hay filesystem: false.
  Future<bool> checkModelExists() async {
    if (kIsWeb) return false;
    if (_useMobileBackend) return FlutterGemmaBackend.instance.isInstalled();
    final modelFile = File(await _modelPath);
    if (!await modelFile.exists()) return false;
    return _hasGgufMagic(modelFile);
  }

  /// Los archivos GGUF empiezan con los bytes mágicos "GGUF" (0x47 0x47 0x55
  /// 0x46). Sirve para descartar un archivo corrupto o vacío sin mirar su peso.
  Future<bool> _hasGgufMagic(File file) async {
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final header = await raf.read(4);
      return header.length == 4 &&
          header[0] == 0x47 &&
          header[1] == 0x47 &&
          header[2] == 0x55 &&
          header[3] == 0x46;
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// La IA está disponible si el modelo está descargado localmente
  /// (o si estamos en web y ya hay un motor sano respondiendo).
  Future<bool> isAvailable() async {
    if (!_premiumUnlocked) return false; // la IA es premium
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
    // Descargamos a un temporal y solo lo renombramos al nombre final cuando
    // terminó completo. Así el archivo final SOLO existe si la descarga acabó
    // (una descarga interrumpida queda como .part y no cuenta como instalada).
    final partPath = '$savePath.part';

    final alreadyDownloaded = await checkModelExists();
    if (alreadyDownloaded) {
      downloadProgress.value = 1.0;
      statusNotifier.value = 'Modelo listo.';
      return;
    }

    statusNotifier.value = 'Iniciando descarga de Gemma 4 E2B (QAT Q2_K)…';
    downloadProgress.value = 0.0;

    try {
      // Limpia un .part previo a medias para no reanudar un archivo corrupto.
      final partFile = File(partPath);
      if (await partFile.exists()) {
        await partFile.delete();
      }
      await _dio.download(
        _modelUrl,
        partPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            downloadProgress.value = progress;
            final percent = (progress * 100).round();
            statusNotifier.value = 'Descargando modelo local: $percent%';
          }
        },
      );
      // Rename atómico: el archivo final aparece de golpe, ya completo.
      await File(partPath).rename(savePath);

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
      // Si quedó el motor cargado sin inferencias en curso (p.ej. tras el
      // warm-up del arranque), arma igual el apagado por inactividad para no
      // retener ~2 GB de RAM esperando un uso que quizá no llegue pronto.
      if (_initialized && _pendingInferences == 0) _armIdleUnload();
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
    if (!_premiumUnlocked) return; // sin premium no se calienta el motor
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
    const depthInstruction = 'Las preguntas deben ser CORTAS, NATURALES y DIRECTAS, como las haría una '
        'persona al hablar: pocas palabras (menos de 12), UNA sola idea. '
        'PROHIBIDO el relleno académico o pomposo: nada de "se describe", "acción fundamental", '
        '"en el versículo proporcionado/dado", "según el texto bíblico", ni frases rebuscadas. '
        'Pueden tener algo de fondo (no triviales), pero SIEMPRE preguntadas de forma simple. '
        'CONCRETAS: pregunta por un dato PUNTUAL que esté en el texto (una palabra, un nombre, '
        'una acción, un lugar, un orden), con respuesta breve y literal. PROHIBIDO lo vago, '
        'interpretativo o genérico: nada de "¿qué enseña?", "¿cuál es el propósito/mensaje?", '
        '"¿qué representa?", "¿qué reflexión?". '
        'Ejemplo MAL (rebuscado): "¿Qué acción fundamental se describe como el inicio de la existencia en el versículo proporcionado?". '
        'Ejemplo MAL (genérico): "¿Qué nos enseña este versículo?". '
        'Ejemplo BIEN (directo): "¿Qué hizo Dios al principio?". '
        'EXACTITUD: la respuesta correcta debe poder verificarse SIEMPRE con el texto dado y ser '
        'inequívoca; nunca inventes datos que no estén en el texto ni hagas preguntas sin respuesta '
        'clara. Dentro de eso está PERMITIDO ser astuto: trampas sutiles, enunciados falsos con un '
        'error fino y distractores muy plausibles están bien, mientras la respuesta correcta siga '
        'siendo deducible del texto.';

    final isMulti = verses.length > 1;

    final String textBlock;
    final String formatBlock;
    if (isMulti) {
      final n = verses.length;
      final buffer = StringBuffer();
      for (var i = 0; i < n; i++) {
        buffer.writeln('Texto ${i + 1} (${verses[i].reference}): "${verses[i].verseText}"');
      }
      textBlock = 'Textos a evaluar ($n):\n${buffer.toString().trimRight()}';

      // Una pregunta POR TEXTO, en un array con "forText". El modelo respeta
      // mucho mejor "esta pregunta es para ESTE texto" por elemento que "reparte
      // 3 preguntas en un objeto" (antes lumpeaba y dejaba el último texto sin
      // pregunta). openQuestion va al Texto 3 si existe; si hay 2 textos, al 2.
      final openForText = n >= 3 ? 3 : n;
      formatBlock =
          'Genera EXACTAMENTE 3 preguntas: una "trueFalse", una "multipleChoice" y una "openQuestion". '
          'Cada una trata SOLO sobre el texto indicado en su "forText". Asignación OBLIGATORIA: '
          'trueFalse → Texto 1; multipleChoice → Texto 2; openQuestion → Texto $openForText. '
          'Es OBLIGATORIO cubrir los $n textos; ninguno puede quedar sin su pregunta. '
          'Preguntas CORTAS; el "statement" del trueFalse es una AFIRMACIÓN declarativa SOBRE EL TEXTO que se pueda juzgar como verdadera o falsa: NUNCA una pregunta (sin "¿" ni "?"). Escríbela con TUS palabras a partir del texto; NO copies este ejemplo, es solo de FORMATO: "$_tfFormatExample". Ej INVÁLIDO: "¿Qué había sobre las aguas?". Si el trueFalse es falso, el error debe ser comprobable con el texto (puede ser sutil), y asegúrate de que "isTrue" sea COHERENTE con la afirmación; '
          'multipleChoice con "correct" breve y exactamente 3 "distractors" breves; los 3 distractores deben ser del MISMO tipo, categoría y forma gramatical que "correct", de modo que las 4 opciones encajen naturalmente al responder la pregunta (si reemplazas cualquier opción en la pregunta, debe leerse coherente). NO mezcles categorías (p.ej. si la respuesta es una descripción/estado, los distractores también; no pongas nombres de cosas); '
          'la openQuestion es UNA sola pregunta corta (NO juntes dos preguntas con "y").\n'
          'Formato de salida OBLIGATORIO, EXACTAMENTE este array (sin texto adicional antes ni después):\n'
          '{"questions":[\n'
          '{"forText":1,"type":"trueFalse","statement":"...","isTrue":true},\n'
          '{"forText":2,"type":"multipleChoice","question":"...","correct":"...","distractors":["...","...","..."]},\n'
          '{"forText":$openForText,"type":"openQuestion","question":"..."}\n'
          ']}';
    } else {
      textBlock = 'Texto a evaluar (${verses.first.reference}): "${verses.first.verseText}"';
      formatBlock =
          'Genera exactamente 3 preguntas sobre el texto:\n'
          '1. "trueFalse": una AFIRMACIÓN declarativa CORTA SOBRE EL TEXTO (NUNCA una pregunta; sin "¿" ni "?") con su veredicto "isTrue" COHERENTE. Escríbela con TUS palabras a partir del texto; NO copies este ejemplo, es solo de FORMATO: "$_tfFormatExample". Ej INVÁLIDO: "¿Qué había sobre las aguas?". Si es falsa, el error debe ser comprobable con el texto (puede ser sutil).\n'
          '2. "multipleChoice": pregunta CORTA con "correct" (breve) y "distractors" (exactamente 3, breves). Los 3 distractores deben ser del MISMO tipo, categoría y forma gramatical que "correct", para que las 4 opciones encajen al responder la pregunta (si reemplazas cualquier opción en la pregunta, debe leerse coherente). NO mezcles categorías (si la respuesta es una descripción/estado, los distractores también; no pongas nombres de cosas).\n'
          '3. "openQuestion": UNA sola pregunta abierta, CORTA (una frase), que se responda explicando con pocas palabras. NO juntes dos preguntas en una (nada de "explica X y reflexiona sobre Y").\n'
          'Cada sección debe evaluar un aspecto DIFERENTE del texto.\n'
          'Formato de salida OBLIGATORIO: un ÚNICO objeto JSON, sin envolturas, sin "questions", sin arrays:\n'
          '{"trueFalse":{"statement":"...","isTrue":true},"multipleChoice":{"question":"...","correct":"...","distractors":["...","...","..."]},"openQuestion":{"question":"..."}}';
    }

    // El modelo on-device a veces ignora la estructura (devuelve un array, JSON
    // truncado o malformado) en una generación concreta; re-rolamos unas pocas
    // veces antes de propagar el error a la UI.
    Object? lastError;
    for (var attempt = 1; attempt <= _quizMaxAttempts; attempt++) {
      final entropy = _seedRandom.nextInt(100000);
      final style = _quizStyles[_seedRandom.nextInt(_quizStyles.length)];
      final tfFocus = _quizFocusAngles[_seedRandom.nextInt(_quizFocusAngles.length)];
      final mcFocus = _quizFocusAngles[_seedRandom.nextInt(_quizFocusAngles.length)];
      final varietyHint =
          'VARIEDAD: cada cuestionario debe ser DISTINTO a los anteriores; no repitas el mismo '
          'patrón ni la misma frase de siempre. Varía el ángulo, pero la pregunta debe seguir siendo '
          'CONCRETA y de respuesta clara (no la hagas rebuscada por buscar variedad). Esta vez parte '
          'la de verdadero/falso desde $tfFocus, y la de opción múltiple desde $mcFocus. $style';
      final prompt = 'Eres un generador de cuestionarios en español para una app de memorización de versículos bíblicos.\n'
          'Semilla de variación aleatoria: $entropy\n'
          '$textBlock\n\n'
          '$formatBlock\n\n'
          '$depthInstruction\n'
          '$varietyHint\n'
          'IDIOMA OBLIGATORIO: TODO en ESPAÑOL (preguntas, enunciados y opciones). '
          'NUNCA respondas en inglés ni en otro idioma, aunque la semilla o el patrón te tienten. '
          'Responde únicamente con el JSON, sin texto adicional.';
      try {
        final content = await _chat(
          prompt,
          temperature: _quizTemperature,
          maxTokens: _quizMaxTokens,
          jsonSchema: _quizRoundSetSchema,
        );
        debugPrint('=== RESPUESTA IA LOCAL QUIZ CRUDA (intento $attempt) ===\n$content\n=====================================');
        final parsed = _parseQuizRoundSet(content);
        // El verdadero/falso lo construimos NOSOTROS a partir del texto para no
        // depender de la etiqueta del modelo (que a veces afirmaba algo cierto y
        // lo marcaba como falso). El trueFalse del modelo se descarta.
        return AiQuizRoundSet(
          trueFalse: _buildCodeTrueFalse(verses.first.verseText),
          multipleChoice: parsed.multipleChoice,
          openQuestion: parsed.openQuestion,
        );
      } catch (e) {
        lastError = e;
        debugPrint('Generación de quiz falló (intento $attempt/$_quizMaxAttempts): $e');
      }
    }
    throw StateError('No se pudo generar el quiz tras $_quizMaxAttempts intentos: $lastError');
  }

  /// Palabras de contenido "plausibles pero de otro tema" para fabricar una
  /// versión FALSA del versículo (sustituyendo una palabra por una de aquí que
  /// no esté en el texto). Bíblicas y comunes para que suene natural.
  static const List<String> _tfFalsePool = [
    'cielo', 'tierra', 'luz', 'agua', 'fuego', 'viento', 'monte', 'mar',
    'desierto', 'ciudad', 'templo', 'pueblo', 'rey', 'profeta', 'ángel',
    'justicia', 'pecado', 'gloria', 'pan', 'vino', 'camino', 'verdad', 'vida',
    'muerte', 'día', 'noche', 'sol', 'luna', 'estrella', 'árbol', 'fruto',
    'piedra', 'río', 'monte', 'siervo', 'palabra', 'mano', 'corazón',
  ];

  /// Construye en CÓDIGO el enunciado de verdadero/falso a partir del texto,
  /// sin depender de la etiqueta del modelo. TRUE = el versículo tal cual;
  /// FALSE = el versículo con UNA palabra de contenido sustituida por otra que
  /// no aparece en él → afirmación realmente falsa (y la etiqueta nunca miente).
  AiTrueFalseRound _buildCodeTrueFalse(String verseText) {
    final clean = verseText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty || _seedRandom.nextBool()) {
      return AiTrueFalseRound(statement: clean, isTrue: true);
    }
    String norm(String w) =>
        w.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñü]'), '');
    const stop = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'y',
      'o', 'en', 'a', 'que', 'se', 'su', 'sus', 'con', 'por', 'para', 'al',
      'lo', 'le', 'es', 'fue', 'era', 'sin', 'sobre', 'mi', 'tu', 'no', 'ni',
      'como', 'más', 'muy', 'ya', 'esto', 'esta', 'este',
    };
    final tokens = clean.split(' ');
    final verseWords = {for (final t in tokens) norm(t)}..remove('');
    final contentIdx = [
      for (var i = 0; i < tokens.length; i++)
        if (norm(tokens[i]).length >= 4 && !stop.contains(norm(tokens[i]))) i,
    ];
    final candidates =
        _tfFalsePool.where((w) => !verseWords.contains(norm(w))).toList();
    if (contentIdx.isEmpty || candidates.isEmpty) {
      // No se pudo alterar de forma segura → devolvemos una verdadera.
      return AiTrueFalseRound(statement: clean, isTrue: true);
    }
    final idx = contentIdx[_seedRandom.nextInt(contentIdx.length)];
    final replacement = candidates[_seedRandom.nextInt(candidates.length)];
    final orig = tokens[idx];
    // Conserva puntuación al inicio/fin y la mayúscula inicial de la palabra.
    final lead = RegExp(r'^[^0-9A-Za-zÁÉÍÓÚÜÑáéíóúüñ]*').firstMatch(orig)!.group(0)!;
    final trail = RegExp(r'[^0-9A-Za-zÁÉÍÓÚÜÑáéíóúüñ]*$').firstMatch(orig)!.group(0)!;
    final coreStart = lead.length;
    final wasUpper = orig.length > coreStart &&
        orig[coreStart] == orig[coreStart].toUpperCase() &&
        orig[coreStart] != orig[coreStart].toLowerCase();
    final repl = wasUpper
        ? '${replacement[0].toUpperCase()}${replacement.substring(1)}'
        : replacement;
    tokens[idx] = '$lead$repl$trail';
    return AiTrueFalseRound(statement: tokens.join(' '), isTrue: false);
  }

  /// Parsea la respuesta del quiz con el normalizador tolerante: acepta el
  /// objeto esperado, un array de sets, `{questions:[...]}` o un array de
  /// preguntas tipadas, con nombres de campo variables.
  AiQuizRoundSet _parseQuizRoundSet(String content) {
    final set = AiQuizRoundSet.lenient(_decodeJsonStructure(content));
    // (El verdadero/falso del modelo se descarta y se genera en código; no lo
    // validamos aquí.) El resto del cuestionario DEBE estar en español: si el
    // modelo se fue al inglés, lo rechazamos para que el bucle re-genere.
    if (_looksEnglish(set.multipleChoice.question) ||
        _looksEnglish(set.openQuestion.question)) {
      throw const FormatException('El quiz llegó en inglés, no en español.');
    }
    return set;
  }

  /// Heurística simple de inglés: cuenta marcadores que no existen en español.
  bool _looksEnglish(String s) {
    final words = s
        .toLowerCase()
        .split(RegExp(r'[^a-záéíóúñü]+'))
        .where((w) => w.isNotEmpty)
        .toSet();
    const markers = {
      'what', 'did', 'say', 'said', 'is', 'are', 'was', 'were', 'the',
      'and', 'god', 'how', 'why', 'who', 'where', 'of', 'this', 'that',
      'does', 'do', 'which', 'true', 'false', 'answer', 'verse',
    };
    return words.where(markers.contains).length >= 2;
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
    final levelHint = level == 1
        ? 'un cambio sutil (un sinónimo cercano)'
        : level == 2
            ? 'cambios sutiles, con palabras muy parecidas a las originales'
            : 'cambios muy sutiles (conectores pequeños o sinónimos casi idénticos)';

    // Prompt corto y directo: los prompts largos hacían que el modelo on-device
    // degenerara (escupía "<unk><unk>…" sin generar JSON).
    Object? lastError;
    for (var attempt = 1; attempt <= _quizMaxAttempts; attempt++) {
      final prompt = 'Toma el versículo y REEMPLAZA EXACTAMENTE $level palabra(s) por otra(s) palabra(s) DIFERENTE(S) e incorrecta(s) ("intrusos"), con $levelHint. '
          'Cada palabra intrusa debe ser DISTINTA a la que reemplaza (NO repitas la misma palabra). El resto del versículo queda IGUAL.\n'
          'Ejemplo: versículo "Dios creó el cielo" → alterado "Dios formó el cielo", intruso "formó" (cambió "creó" por "formó").\n'
          'Versículo ($reference): "$verseText"\n\n'
          'Responde SOLO con este JSON, sin nada más:\n'
          '{"alteredVerse": "el versículo con esas $level palabra(s) ya cambiada(s)", "intruderWords": ["las palabras NUEVAS que pusiste, no las originales"]}';
      try {
        final content = await _chat(
          prompt,
          temperature: 0.5,
          maxTokens: 600,
          jsonSchema: _intruderVerseSchema,
        );
        debugPrint('=== RESPUESTA IA LOCAL INTRUSO CRUDA (intento $attempt) ===\n$content\n=====================================');
        final set = IntruderVerseSet.lenient(_decodeJsonStructure(content));
        validateIntruderSet(set, verseText, level); // lanza si no es jugable
        return set;
      } catch (e) {
        lastError = e;
        debugPrint('Generación de palabras intrusas falló (intento $attempt/$_quizMaxAttempts): $e');
      }
    }
    // Garantía a nivel de código: si la IA no logró un ejercicio válido, lo
    // construimos nosotros para que NUNCA salga roto (ni idéntico al original).
    debugPrint('Intrusas: usando fallback de código tras fallar la IA ($lastError).');
    return buildFallbackIntruderVerse(verseText, level, _seedRandom);
  }

  static String _intruderNorm(String w) =>
      w.toLowerCase().replaceAll(RegExp(r'[^0-9a-záéíóúüñ]'), '');

  /// Heurística de plural en español para concordar el intruso en número (evita
  /// meter una palabra singular donde el texto va en plural). Excluye singulares
  /// comunes acabados en -s poco frecuentes en versículos.
  static bool _isPluralWord(String norm) {
    if (norm.length < 4 || !norm.endsWith('s')) return false;
    const singularEndingInS = {'jesus', 'dios', 'mies', 'pais', 'mas', 'jamas'};
    return !singularEndingInS.contains(norm);
  }

  /// Pluraliza una palabra en español (regla básica: vocal → +s, consonante →
  /// +es, terminación en -z → -ces).
  static String _pluralize(String w) {
    if (w.isEmpty) return w;
    final last = w[w.length - 1].toLowerCase();
    if ('aeiouáéíóú'.contains(last)) return '${w}s';
    if (last == 'z') return '${w.substring(0, w.length - 1)}ces';
    return '${w}es';
  }

  /// Verifica que el ejercicio es JUGABLE y real, tal como lo consume el juego:
  /// el versículo cambió, las palabras intrusas son NUEVAS (no estaban en el
  /// original) y aparecen EXACTAMENTE [level] veces en el texto alterado.
  @visibleForTesting
  static void validateIntruderSet(IntruderVerseSet set, String original, int level) {
    final originalWords = original.split(RegExp(r'\s+')).map(_intruderNorm).where((w) => w.isNotEmpty).toList();
    final alteredWords = set.alteredVerse.split(RegExp(r'\s+')).map(_intruderNorm).where((w) => w.isNotEmpty).toList();

    if (alteredWords.join(' ') == originalWords.join(' ')) {
      throw const FormatException('El versículo alterado es idéntico al original.');
    }

    final originalSet = originalWords.toSet();
    final intruderNorms = set.intruderWords.map(_intruderNorm).where((w) => w.isNotEmpty).toSet();
    if (intruderNorms.isEmpty) {
      throw const FormatException('No hay palabras intrusas.');
    }
    for (final w in intruderNorms) {
      if (originalSet.contains(w)) {
        throw FormatException('La intrusa "$w" ya estaba en el versículo original.');
      }
    }
    final positions = alteredWords.where(intruderNorms.contains).length;
    if (positions != level) {
      throw FormatException('Se esperaban $level intrusas en el texto, hay $positions.');
    }
  }

  /// Sinónimos cercanos (registro bíblico) que CONSERVAN género y número, para
  /// que el intruso suene coherente con su artículo (nada de "la mundo"). Sólo
  /// red de seguridad cuando el modelo no coopera.
  static const Map<String, String> _intruderSynonyms = {
    // Verbos (sin concordancia de género).
    'creó': 'formó', 'creo': 'formo', 'creado': 'formado', 'hizo': 'formó',
    'dijo': 'habló', 'vio': 'miró', 'amó': 'quiso', 'dio': 'entregó',
    'llamó': 'nombró', 'separó': 'dividió', 'bendijo': 'consagró',
    // Sustantivos masculinos → masculinos.
    'principio': 'comienzo', 'comienzo': 'inicio', 'dios': 'señor', 'señor': 'dios',
    'cielo': 'firmamento', 'mundo': 'planeta', 'espíritu': 'aliento',
    'día': 'amanecer', 'camino': 'sendero', 'corazón': 'pecho', 'amor': 'cariño',
    'pueblo': 'reino', 'rey': 'príncipe', 'hijo': 'heredero', 'padre': 'progenitor',
    'poder': 'dominio', 'temor': 'recelo', 'gozo': 'júbilo', 'pecado': 'error',
    // Sustantivos femeninos → femeninos.
    'tierra': 'arena', 'luz': 'llama', 'vida': 'existencia', 'verdad': 'certeza',
    'palabra': 'voz', 'paz': 'calma', 'gloria': 'honra', 'fe': 'esperanza',
    'noche': 'sombra', 'gracia': 'merced', 'fuerza': 'firmeza', 'mujer': 'dama',
    'madre': 'señora', 'nación': 'región', 'muerte': 'ruina',
    // Plurales (conservan número).
    'cielos': 'firmamentos', 'tinieblas': 'sombras', 'aguas': 'olas',
    'palabras': 'voces', 'días': 'tiempos',
  };

  /// Pools genéricos por género (cuando una palabra no tiene sinónimo): se elige
  /// según el artículo que la precede para no romper la concordancia.
  static const List<String> _intruderMascGeneric = [
    'firmamento', 'sendero', 'aliento', 'abismo', 'sosiego', 'umbral', 'clamor',
    'designio', 'reino', 'sustento',
  ];
  static const List<String> _intruderFemGeneric = [
    'arena', 'sombra', 'niebla', 'senda', 'calma', 'aurora', 'bruma', 'llama',
    'región', 'firmeza',
  ];
  static const Set<String> _intruderFemDeterminers = {
    'la', 'las', 'una', 'unas', 'esta', 'estas', 'esa', 'esas', 'aquella', 'aquellas',
  };
  static const Set<String> _intruderMascDeterminers = {
    'el', 'los', 'un', 'unos', 'este', 'estos', 'ese', 'esos', 'aquel', 'aquellos',
  };

  /// Palabras-función que NUNCA se reemplazan (romperían la frase): artículos,
  /// preposiciones, conjunciones, pronombres y auxiliares comunes.
  static const Set<String> _intruderStopWords = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'lo', 'le', 'les',
    'y', 'o', 'u', 'e', 'ni', 'de', 'del', 'a', 'al', 'en', 'con', 'por', 'para',
    'sin', 'sobre', 'tras', 'que', 'se', 'su', 'sus', 'mi', 'tu', 'me', 'te', 'nos',
    'es', 'fue', 'era', 'son', 'no', 'si', 'sí', 'como', 'más', 'muy', 'ya', 'ha', 'han',
  };

  /// Construye un ejercicio de intrusas válido en puro código: reemplaza
  /// exactamente [level] palabras de contenido por otras DISTINTAS, nuevas y
  /// coherentes con su artículo.
  @visibleForTesting
  static IntruderVerseSet buildFallbackIntruderVerse(String original, int level, math.Random rng) {
    final clean = original.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tokens = clean.split(' ');
    final originalNorms = tokens.map(_intruderNorm).toSet();
    final usedNew = <String>{...originalNorms};

    String replaceCore(String token, String newCore) {
      final m = RegExp(r'^([^0-9a-záéíóúüñ]*)(.*?)([^0-9a-záéíóúüñ]*)$', caseSensitive: false)
          .firstMatch(token);
      final lead = m?.group(1) ?? '';
      final trail = m?.group(3) ?? '';
      final core = m?.group(2) ?? token;
      final cased = core.isNotEmpty && core[0] == core[0].toUpperCase()
          ? newCore[0].toUpperCase() + newCore.substring(1)
          : newCore;
      return '$lead$cased$trail';
    }

    // Elige un genérico coherente con el ARTÍCULO previo (género) y con el
    // NÚMERO de la palabra que reemplaza (singular/plural), y de forma
    // ALEATORIA para no repetir siempre la misma palabra (p.ej. "firmamento").
    String pickGeneric(int idx) {
      final prev = idx > 0 ? _intruderNorm(tokens[idx - 1]) : '';
      final List<String> pool;
      if (_intruderFemDeterminers.contains(prev)) {
        pool = _intruderFemGeneric;
      } else if (_intruderMascDeterminers.contains(prev)) {
        pool = _intruderMascGeneric;
      } else {
        pool = [..._intruderMascGeneric, ..._intruderFemGeneric];
      }
      final plural = _isPluralWord(_intruderNorm(tokens[idx]));
      final shuffled = [...pool]..shuffle(rng);
      for (final w in shuffled) {
        final cand = plural ? _pluralize(w) : w;
        if (!usedNew.contains(cand)) return cand;
      }
      return '';
    }

    // Candidatos: SÓLO palabras de contenido (>= 3 letras y no función),
    // barajados, con prioridad para las que tienen sinónimo (más plausibles).
    bool isContent(int i) {
      final c = _intruderNorm(tokens[i]);
      return c.length >= 3 && !_intruderStopWords.contains(c);
    }

    final candidates = [for (var i = 0; i < tokens.length; i++) if (isContent(i)) i]..shuffle(rng);
    candidates.sort((a, b) {
      final aHas = _intruderSynonyms.containsKey(_intruderNorm(tokens[a])) ? 0 : 1;
      final bHas = _intruderSynonyms.containsKey(_intruderNorm(tokens[b])) ? 0 : 1;
      return aHas.compareTo(bHas);
    });

    final intruders = <String>[];
    for (final idx in candidates) {
      if (intruders.length >= level) break;
      final core = _intruderNorm(tokens[idx]);
      var newCore = _intruderSynonyms[core]; // gender-consistent by construction
      if (newCore == null || usedNew.contains(newCore)) {
        newCore = pickGeneric(idx); // gender chosen from the preceding article
      }
      if (newCore.isEmpty || usedNew.contains(newCore)) continue;
      tokens[idx] = replaceCore(tokens[idx], newCore);
      usedNew.add(newCore);
      intruders.add(newCore);
    }

    return IntruderVerseSet(
      alteredVerse: tokens.join(' '),
      intruderWords: intruders,
      explanation: '',
    );
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
    // El modelo on-device a veces devuelve una respuesta VACÍA en una
    // generación concreta; sin reintento, el prefetch fallaba siempre y el
    // ejercicio se quedaba sin distractores de IA. Reintentamos unas pocas
    // veces y, si aun así no hay nada, devolvemos vacío (el ejercicio usa su
    // banco local) SIN lanzar, para no spamear ni colgar el spinner.
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final entropy = _seedRandom.nextInt(100000);
        final prompt =
            'Eres un tutor de memorización de versículos en español.\n'
            'Semilla de variación aleatoria: $entropy\n'
            'Texto ($reference): "$verseText"\n\n'
            'Devuelve "distractors": exactamente $count PALABRAS sueltas (una sola palabra, sin frases) '
            'que funcionen como opciones INCORRECTAS pero MUY confundibles en un ejercicio de rellenar '
            'huecos de este texto. Cada distractor debe poder colocarse en lugar de ALGUNA palabra del '
            'versículo y sonar casi creíble: usa sinónimos cercanos, la misma familia o raíz, otra '
            'conjugación, o palabras de longitud y forma parecidas a las del texto, y que encajen '
            'gramaticalmente (mismo tipo: si reemplaza un verbo, que sea verbo; si un sustantivo, '
            'sustantivo; respeta género/número). '
            'PROHIBIDO: palabras que ya estén en el texto, y palabras genéricas sin relación con el '
            'versículo. Todo en español. Solo el JSON.';
        final content = await _chat(
          prompt,
          temperature: 0.9,
          maxTokens: 160,
          jsonSchema: _distractorSchema,
        );
        final decoded = _decodeJsonObject(content);
        final raw = (decoded['distractors'] as List?) ?? const [];
        final words = <String>[];
        for (final item in raw) {
          final word = item.toString().trim().split(RegExp(r'\s+')).first;
          if (word.length > 2 && !words.contains(word)) words.add(word);
        }
        if (words.isNotEmpty) return words;
        lastError = StateError('lista de distractores vacía');
      } catch (e) {
        lastError = e;
        debugPrint('Distractores IA fallaron (intento $attempt/$maxAttempts): $e');
      }
    }
    debugPrint('Distractores IA sin resultado tras $maxAttempts intentos '
        '($lastError); el ejercicio usará su banco local.');
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Prefetch en segundo plano (take-once): arranca la generación ANTES de que
  // el usuario llegue al ejercicio. El primer consumidor TOMA el resultado (lo
  // saca del caché); un re-uso posterior (ej. "Reintentar") genera fresco. La
  // inferencia ya está serializada, así que esto sólo adelanta trabajo, no choca.
  // ---------------------------------------------------------------------------
  final Map<String, Future<IntruderVerseSet>> _intruderPrefetch = {};
  final Map<String, Future<List<String>>> _distractorPrefetch = {};

  String _intruderKey(String reference, int level) => '$reference##$level';

  void prefetchIntruderVerse({
    required String reference,
    required String verseText,
    required int level,
  }) {
    if (!_premiumUnlocked) return; // IA premium
    if (_voiceCaptureActive) return; // no competir con Whisper en CPU
    final key = _intruderKey(reference, level);
    if (_intruderPrefetch.containsKey(key)) return;
    final f = generateIntruderVerse(reference: reference, verseText: verseText, level: level);
    _intruderPrefetch[key] = f;
    unawaited(f.then((_) {}, onError: (_) => _intruderPrefetch.remove(key)));
  }

  /// Devuelve el intruso pre-generado para (reference, level) y lo SACA del
  /// caché, o null si no se prefetchó.
  Future<IntruderVerseSet>? takePrefetchedIntruder({
    required String reference,
    required int level,
  }) =>
      _intruderPrefetch.remove(_intruderKey(reference, level));

  void prefetchCompletionDistractors({
    required String reference,
    required String verseText,
  }) {
    if (!_premiumUnlocked) return; // IA premium
    if (_voiceCaptureActive) return; // no competir con Whisper en CPU
    if (_distractorPrefetch.containsKey(reference)) return;
    final f = generateCompletionDistractors(reference: reference, verseText: verseText);
    _distractorPrefetch[reference] = f;
    unawaited(f.then((_) {}, onError: (_) => _distractorPrefetch.remove(reference)));
  }

  /// Distractores pre-generados para [reference] (los SACA del caché), o null.
  Future<List<String>>? takePrefetchedDistractors(String reference) =>
      _distractorPrefetch.remove(reference);

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
        // Prompt corto y directo: los prompts largos disparaban en el modelo
        // on-device un bucle degenerado (repetía "system..." sin generar JSON).
        final prompt = 'Evalúa si la respuesta del usuario es válida para la pregunta sobre el versículo. Sé estricto pero justo.\n'
            'Versículo: "$verseText"\n'
            'Pregunta: "$question"\n'
            'Respuesta del usuario: "${userAnswer.trim()}"\n\n'
            'Es correcta si se relaciona con la pregunta y muestra que entendió el versículo, aunque sea simple o informal. '
            'Es incorrecta si habla de otra cosa (deportes, comida…), está vacía, evade o es incoherente.\n'
            'Responde SOLO con este JSON, sin nada más antes ni después:\n'
            '{"isCorrect": true, "feedback": "frase corta del porqué"}';

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
  /// Punto único de inferencia: serializa todas las llamadas (una a la vez) para
  /// no crashear el motor nativo y para que el prefetch en background no choque
  /// con una generación en curso.
  Future<String> _chat(
    String prompt, {
    required double temperature,
    required int maxTokens,
    Map<String, dynamic>? jsonSchema,
  }) {
    // Estamos por usar el motor: cancela cualquier apagado pendiente y cuenta
    // esta inferencia como "en vuelo" para no descargar el modelo a mitad.
    _idleTimer?.cancel();
    _pendingInferences++;
    final result = _inferenceChain.then((_) => _chatImpl(
          prompt,
          temperature: temperature,
          maxTokens: maxTokens,
          jsonSchema: jsonSchema,
        ));
    // El siguiente en la cola espera a este, haya éxito o error (sin propagar).
    _inferenceChain = result.then((_) {}, onError: (_) {});
    result.whenComplete(() {
      _pendingInferences--;
      if (_pendingInferences == 0) _armIdleUnload();
    });
    return result;
  }

  void _armIdleUnload() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleUnloadTimeout, () {
      if (_pendingInferences == 0) unawaited(unloadForIdle());
    });
  }

  /// Apaga el motor y libera su memoria: en desktop detiene el subproceso
  /// `llama-server`; en móvil cierra el modelo Gemma on-device. La siguiente
  /// inferencia lo re-levanta automáticamente (initLlm en _chatImpl).
  Future<void> unloadForIdle() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (!_initialized || _pendingInferences > 0) return;
    _initialized = false;
    _initInFlight = null;
    try {
      if (_useMobileBackend) {
        await FlutterGemmaBackend.instance.dispose();
      } else {
        await LlamaServerManager.instance.stop();
      }
      statusNotifier.value = 'IA en reposo (memoria liberada).';
      debugPrint('IA local descargada por inactividad.');
    } catch (e) {
      debugPrint('Error al descargar IA local: $e');
    }
  }

  Future<String> _chatImpl(
    String prompt, {
    required double temperature,
    required int maxTokens,
    Map<String, dynamic>? jsonSchema,
  }) async {
    // Gate central: sin premium no se hace NINGUNA inferencia con IA. Los
    // ejercicios que llaman a la IA deben tolerar este fallo y usar su fallback.
    if (!_premiumUnlocked) {
      throw StateError('Los ejercicios con IA requieren premium.');
    }
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
        // CLAVE: desactiva la fase de "razonamiento" del modelo. Sin esto, el
        // modelo gasta cientos de tokens PENSANDO antes de responder y, con un
        // max_tokens acotado, se queda sin presupuesto y devuelve content VACÍO
        // (finish_reason: length) → fallaban distractores/eval/intrusas. Sin
        // razonar, responde el JSON directo: mucho más rápido y fiable.
        'chat_template_kwargs': {'enable_thinking': false},
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
