import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Backend de inferencia on-device para móvil (Android / iOS).
///
/// En escritorio la IA corre vía `llama-server` (subproceso + HTTP), camino
/// imposible en móvil: no se puede spawnear un binario ni abrir un servidor
/// local. Aquí la inferencia corre 100% en el dispositivo con flutter_gemma
/// (MediaPipe / LiteRT-LM, GPU). El modelo se descarga una vez y se cachea.
///
/// Todo flutter_gemma queda aislado en este archivo: [LocalLlmService] sólo
/// llama estos métodos con tipos planos, sin acoplarse al plugin.
class FlutterGemmaBackend {
  FlutterGemmaBackend._();
  static final FlutterGemmaBackend instance = FlutterGemmaBackend._();

  /// Modelo Gemma para móvil. Configurable por dart-define para poder apuntar
  /// a otra variante/cuantización sin recompilar el código. Por defecto un
  /// Gemma 3 1B IT en formato `.task` (ligero, apto para teléfono).
  static const String _modelUrl = String.fromEnvironment(
    'GEMMA_MOBILE_MODEL_URL',
    defaultValue:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q8_ekv1280.task',
  );

  /// Token de Hugging Face si el modelo está detrás de gate. Vacío = público.
  static const String _hfToken =
      String.fromEnvironment('HF_TOKEN', defaultValue: '');

  static const int _maxTokens = 1024;

  InferenceModel? _model;
  bool _initialized = false;
  Future<void>? _initInFlight;

  /// True si ya hay un modelo activo instalado y listo para cargar.
  Future<bool> isInstalled() async {
    try {
      await FlutterGemma.initialize(
        huggingFaceToken: _hfToken.isEmpty ? null : _hfToken,
      );
      return FlutterGemma.hasActiveModel();
    } catch (e) {
      debugPrint('flutter_gemma isInstalled falló: $e');
      return false;
    }
  }

  bool get isReady => _initialized;

  /// Descarga única del modelo (cacheado tras la primera vez). Reporta avance
  /// 0..1 y estado textual a los callbacks para alimentar la UI existente.
  Future<void> downloadModel({
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Iniciando descarga de Gemma (on-device)…');
    await FlutterGemma.initialize(
      huggingFaceToken: _hfToken.isEmpty ? null : _hfToken,
    );

    if (FlutterGemma.hasActiveModel()) {
      onProgress?.call(1.0);
      onStatus?.call('Modelo listo.');
      return;
    }

    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(_modelUrl, token: _hfToken.isEmpty ? null : _hfToken)
        .withProgress((percent) {
      final progress = (percent / 100).clamp(0.0, 1.0);
      onProgress?.call(progress);
      onStatus?.call('Descargando modelo on-device: $percent%');
    }).install();

    onProgress?.call(1.0);
    onStatus?.call('Descarga de IA completada con éxito.');
  }

  /// Carga el modelo en memoria (GPU). Idempotente y deduplicado.
  Future<void> init({void Function(String status)? onStatus}) {
    if (_initialized) return Future.value();
    return _initInFlight ??= _doInit(onStatus).whenComplete(() {
      _initInFlight = null;
    });
  }

  Future<void> _doInit(void Function(String status)? onStatus) async {
    onStatus?.call('Inicializando IA on-device…');
    await FlutterGemma.initialize(
      huggingFaceToken: _hfToken.isEmpty ? null : _hfToken,
    );
    if (!FlutterGemma.hasActiveModel()) {
      throw StateError('El modelo de IA on-device no está instalado.');
    }
    _model = await FlutterGemma.getActiveModel(
      maxTokens: _maxTokens,
      preferredBackend: PreferredBackend.gpu,
    );
    _initialized = true;
    onStatus?.call('IA lista offline.');
  }

  /// Una inferencia: crea una sesión efímera, manda el prompt y devuelve el
  /// texto. Las sesiones son baratas; el modelo (pesado) se reutiliza.
  Future<String> chat(
    String prompt, {
    required double temperature,
    required int randomSeed,
    void Function(String status)? onStatus,
  }) async {
    if (!_initialized) {
      await init(onStatus: onStatus);
    }
    final session = await _model!.createSession(
      temperature: temperature,
      topK: 1,
      randomSeed: randomSeed,
    );
    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();
      if (response.trim().isEmpty) {
        throw StateError('La IA on-device devolvió una respuesta vacía.');
      }
      return response.trim();
    } finally {
      await session.close();
    }
  }
}
