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
  /// Gemma 4 E2B IT en formato `.litertlm` (optimizado para LiteRT-LM en móvil).
  static const String _modelUrl = String.fromEnvironment(
    'GEMMA_MOBILE_MODEL_URL',
    defaultValue:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
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

      final filename = 'gemma-4-E2B-it.litertlm';
      final isFilePresent = await FlutterGemma.isModelInstalled(filename);

      if (isFilePresent) {
        if (FlutterGemma.hasActiveModel()) {
          final activeModel = FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
          if (activeModel is InferenceModelSpec &&
              activeModel.fileType == ModelFileType.litertlm &&
              activeModel.modelType == ModelType.gemma4) {
            return true;
          }
        }

        debugPrint('Configurando modelo activo a litertlm/gemma4...');
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        )
            .fromNetwork(_modelUrl, token: _hfToken.isEmpty ? null : _hfToken)
            .install();
        return true;
      }

      return false;
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

    if (await isInstalled()) {
      onProgress?.call(1.0);
      onStatus?.call('Modelo listo.');
      return;
    }

    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    )
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
    if (!await isInstalled()) {
      throw StateError('El modelo de IA on-device no está instalado.');
    }
    try {
      debugPrint('Intentando cargar modelo en GPU...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: _maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (e) {
      debugPrint('Fallo al inicializar GPU ($e). Reintentando en CPU...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: _maxTokens,
        preferredBackend: PreferredBackend.cpu,
      );
    }
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
      topK: 40,
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

  /// Libera el modelo on-device de memoria (pesado). La próxima inferencia lo
  /// recarga on-demand. Se usa para no retener RAM cuando la IA está ociosa.
  Future<void> dispose() async {
    if (_model == null && !_initialized) return;
    try {
      await _model?.close();
    } catch (e) {
      debugPrint('Error cerrando modelo Gemma on-device: $e');
    }
    _model = null;
    _initialized = false;
    _initInFlight = null;
  }
}
