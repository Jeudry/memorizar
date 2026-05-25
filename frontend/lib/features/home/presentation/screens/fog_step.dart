// Generado del refactor de ui_screens.dart.
// _FogStep (recitación con neblina progresiva).
part of '../ui_screens.dart';

class _FogStep extends StatefulWidget {
  final String targetText;
  final int round; // 0,1,2 (Ronda 1, Ronda 2, Ronda 3)
  final bool finished;
  final VoidCallback onRoundCompleted;

  const _FogStep({
    required this.targetText,
    required this.round,
    required this.finished,
    required this.onRoundCompleted,
  });

  @override
  State<_FogStep> createState() => _FogStepState();
}

class _FogStepState extends State<_FogStep>
    with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  bool _isModelDownloaded = false;
  bool _isModelInitializing = false;
  bool _isDownloadingModel = false;
  double _modelDownloadProgress = 0.0;
  String _modelStatus = '';
  String _status = 'Módulo de voz cargando...';
  bool _ready = false;
  bool _listening = false;
  String? _recordedPath;
  Timer? _autoStopTimer;

  late AnimationController _pulse;
  late List<String> _allWords;
  String _recognized = '';
  double _score = 0;
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _allWords = _studyWords(widget.targetText);
    _checkModelStatus();
  }

  @override
  void didUpdateWidget(_FogStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText) {
      _allWords = _studyWords(widget.targetText);
      _score = 0;
      _recognized = '';
    }
    if (oldWidget.round != widget.round) {
      _score = 0;
      _recognized = '';
      _status = 'Ronda cambiada. Presiona recitar.';
    }
  }

  Future<void> _checkModelStatus() async {
    final exists = await WhisperService.instance.checkModelsExist();
    if (!mounted) return;
    setState(() {
      _isModelDownloaded = exists;
    });
    if (exists) {
      await _initWhisper();
    } else {
      setState(() {
        _status = 'El modelo de reconocimiento local (375MB) no está descargado.';
      });
    }
  }

  Future<void> _initWhisper() async {
    setState(() {
      _isModelInitializing = true;
      _status = 'Inicializando motor local...';
    });
    try {
      await WhisperService.instance.initWhisper();
      if (!mounted) return;
      setState(() {
        _isModelDownloaded = true;
        _isModelInitializing = false;
      });
      await _initRecorder();
    } catch (e) {
      debugPrint('Whisper init error: $e');
      if (mounted) {
        setState(() {
          _isModelInitializing = false;
          _status = 'Error al inicializar el reconocimiento de voz.';
        });
      }
    }
  }

  void _downloadModels() {
    setState(() {
      _isDownloadingModel = true;
      _modelDownloadProgress = 0.0;
      _modelStatus = 'Descargando...';
    });

    final service = WhisperService.instance;
    service.downloadProgress.addListener(_onDownloadProgressChanged);
    service.statusNotifier.addListener(_onStatusChanged);

    service.downloadModels().then((_) async {
      service.downloadProgress.removeListener(_onDownloadProgressChanged);
      service.statusNotifier.removeListener(_onStatusChanged);
      if (!mounted) return;
      await _initWhisper();
    }).catchError((e) {
      service.downloadProgress.removeListener(_onDownloadProgressChanged);
      service.statusNotifier.removeListener(_onStatusChanged);
      if (mounted) {
        setState(() {
          _isDownloadingModel = false;
          _status = 'Error al descargar el componente de voz: $e';
        });
      }
    });
  }

  void _onDownloadProgressChanged() {
    if (mounted) {
      setState(() {
        _modelDownloadProgress = WhisperService.instance.downloadProgress.value;
      });
    }
  }

  void _onStatusChanged() {
    if (mounted) {
      setState(() {
        _modelStatus = WhisperService.instance.statusNotifier.value;
      });
    }
  }

  Future<void> _initRecorder() async {
    try {
      final available = await _audioRecorder.hasPermission();
      if (!mounted) return;
      setState(() {
        _ready = available;
        _status = available
            ? 'Toca el micrófono y recita el texto.'
            : 'Permiso de micrófono denegado. Actívalo en configuración del sistema.';
      });
    } catch (e) {
      debugPrint('Recorder init error: $e');
      if (mounted) {
        setState(() {
          _ready = false;
          _status = 'Error al inicializar el grabador de audio.';
        });
      }
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _pulse.dispose();
    try {
      WhisperService.instance.downloadProgress.removeListener(_onDownloadProgressChanged);
      WhisperService.instance.statusNotifier.removeListener(_onStatusChanged);
    } catch (_) {}
    _audioRecorder.stop().then((_) => _audioRecorder.dispose());
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_ready || !_isModelDownloaded) {
      if (!_isModelDownloaded && !_isDownloadingModel && !_isModelInitializing) {
        _downloadModels();
      } else {
        await _initRecorder();
      }
      return;
    }
    if (_listening) {
      await _finishCapture();
      return;
    }
    setState(() {
      _recognized = '';
      _score = 0;
      _listening = true;
      _status = 'Grabando... recita el texto completo de memoria.';
    });

    _autoStopTimer?.cancel();
    final words = widget.targetText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final limitSeconds = ((words / 1.5).ceil() + 6).clamp(8, 90);
    _autoStopTimer = Timer(Duration(seconds: limitSeconds), () {
      if (mounted && _listening) {
        _finishCapture();
      }
    });

    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_fog_${DateTime.now().millisecondsSinceEpoch}.raw';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );
        _recordedPath = path;
        _pulse.repeat();
      }
    } catch (e) {
      debugPrint('Audio Recorder Error: $e');
      if (mounted) {
        setState(() {
          _listening = false;
          _status = 'Error al iniciar la grabación ($e)';
        });
      }
    }
  }

  Future<void> _finishCapture() async {
    if (_finalizing) return;
    _finalizing = true;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _pulse.stop();
    _pulse.value = 0;
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final wavPath = await _convertPcmToWav(path);
        _recordedPath = wavPath;
      }
      if (!mounted) return;
      setState(() {
        _listening = false;
        _status = 'Analizando tu recitación...';
      });

      if (_recordedPath != null) {
        final text = await WhisperService.instance.transcribe(_recordedPath!);
        _gradeReal(text);
      } else {
        setState(() {
          _status = 'No se grabó ningún audio.';
        });
      }
    } catch (e) {
      debugPrint('Error deteniendo grabación: $e');
      if (mounted) {
        setState(() {
          _listening = false;
          _status = 'Error en reconocimiento local: $e';
        });
      }
    } finally {
      _finalizing = false;
    }
  }

  void _gradeReal(String text) {
    if (!mounted) return;
    final score = _speechSimilarity(text, widget.targetText);
    final passed = score >= 0.60;
    setState(() {
      _score = score;
      _recognized = text;
      _status = passed
          ? '¡Excelente recitación!'
          : 'Similitud muy baja (${(score * 100).round()}%). Lee de nuevo con claridad.';
    });

    if (passed) {
      widget.onRoundCompleted();
    }
  }

  Future<String> _convertPcmToWav(String rawPath) async {
    final file = File(rawPath);
    if (!await file.exists()) return rawPath;

    final bytes = await file.readAsBytes();
    final wavHeader = _buildWavHeader(bytes.length);

    final wavPath = rawPath.replaceAll('.raw', '.wav');
    final wavFile = File(wavPath);

    final builder = BytesBuilder();
    builder.add(wavHeader);
    builder.add(bytes);

    await wavFile.writeAsBytes(builder.toBytes());

    try {
      await file.delete();
    } catch (e) {
      debugPrint('Error deleting raw file: $e');
    }

    return wavPath;
  }

  Uint8List _buildWavHeader(int dataLength) {
    final header = Uint8List(44);
    final data = ByteData.view(header.buffer);

    header[0] = 82; // R
    header[1] = 73; // I
    header[2] = 70; // F
    header[3] = 70; // F

    data.setUint32(4, dataLength + 36, Endian.little);

    header[8] = 87;  // W
    header[9] = 65;  // A
    header[10] = 86; // V
    header[11] = 69; // E

    header[12] = 102; // f
    header[13] = 109; // m
    header[14] = 116; // t
    header[15] = 32;  //  

    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 16000, Endian.little);
    data.setUint32(28, 32000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);

    header[36] = 100; // d
    header[37] = 97;  // a
    header[38] = 116; // t
    header[39] = 97;  // a

    data.setUint32(40, dataLength, Endian.little);

    return header;
  }

  bool _isWordFoggy(int globalIndex) {
    switch (widget.round) {
      case 0:
        // Ronda 1: 33% (cada tercera palabra)
        return globalIndex % 3 == 2;
      case 1:
        // Ronda 2: 66% (dos de cada tres)
        return globalIndex % 3 != 0;
      default:
        // Ronda 3: 100%
        return true;
    }
  }

  Widget _buildFoggyVerse(int number, String text, int globalStartIdx) {
    final words = _studyWords(text);
    const style = TextStyle(
      fontSize: 20,
      height: 1.36,
      fontWeight: FontWeight.w900,
      color: RefColors.ink,
      fontFamily: 'Outfit',
    );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Text(
            '$number',
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (var i = 0; i < words.length; i++) ...[
          () {
            final globalIdx = globalStartIdx + i;
            final isFoggy = _isWordFoggy(globalIdx);

            final wordWidget = Text(
              words[i],
              style: style,
            );

            if (isFoggy && !widget.finished) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: wordWidget,
                ),
              );
            }

            return wordWidget;
          }(),
        ],
      ],
    );
  }

  Widget _buildVersesContainer(BuildContext context) {
    final verses = _currentBatchVerses(context);
    if (verses.length == 1) {
      final words = _studyWords(verses.first.text);
      return Container(
        constraints: const BoxConstraints(minHeight: 120),
        alignment: Alignment.center,
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < words.length; i++) ...[
              () {
                final isFoggy = _isWordFoggy(i);
                final wordWidget = Text(
                  words[i],
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.36,
                    fontWeight: FontWeight.w900,
                    color: RefColors.ink,
                    fontFamily: 'Outfit',
                  ),
                );

                if (isFoggy && !widget.finished) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                      child: wordWidget,
                    ),
                  );
                }

                return wordWidget;
              }(),
            ],
          ],
        ),
      );
    }

    var wordsOffset = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < verses.length; i++) ...[
          _buildFoggyVerse(verses[i].number, verses[i].text, wordsOffset),
          if (i < verses.length - 1) const SizedBox(height: 10),
          () {
            wordsOffset += _studyWords(verses[i].text).length;
            return const SizedBox.shrink();
          }(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isModelDownloaded) {
      final downloadPercent = (_modelDownloadProgress * 100).round();
      final displayStatus = _isModelInitializing
          ? 'Configurando módulo de voz...'
          : _modelStatus.startsWith('Descargando')
              ? 'Optimizando archivos...'
              : _modelStatus.contains('con éxito')
                  ? 'Verificando componentes...'
                  : _modelStatus.isEmpty
                      ? 'Iniciando instalación...'
                      : _modelStatus;

      return Glass(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        radius: 24,
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .22),
            RefColors.cyan.withValues(alpha: .12),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.record_voice_over_rounded,
              color: RefColors.cyan,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Reconocimiento Offline Inteligente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RefColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Descarga el componente de voz (375 MB) para recitar tus versos offline con total privacidad y seguridad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RefColors.muted,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            if (_isDownloadingModel || _isModelInitializing) ...[
              Text(
                _isModelInitializing
                    ? 'Configurando módulo...'
                    : 'Preparando motor: $downloadPercent%',
                style: TextStyle(
                  color: RefColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              RefProgress(_modelDownloadProgress.clamp(0.02, 1.0)),
              const SizedBox(height: 8),
              Text(
                displayStatus,
                style: TextStyle(
                  color: RefColors.dim,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _downloadModels,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: RefColors.cool,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Activar Reconocimiento de Voz',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final total = _allWords.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.finished
                    ? 'Recitación completada'
                    : 'Ronda ${widget.round + 1} / 3',
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              if (_score > 0)
                Text(
                  'Similitud: ${(_score * 100).round()}%',
                  style: TextStyle(
                    color: _score >= 0.60 ? RefColors.lime : RefColors.urgent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Text(
                  'Total: $total palabras',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
        Glass(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          gradient: LinearGradient(
            colors: [
              RefColors.violet.withValues(alpha: .22),
              RefColors.cyan.withValues(alpha: .10),
            ],
          ),
          child: _buildVersesContainer(context),
        ),
        const SizedBox(height: 16),
        if (widget.finished)
          Glass(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            color: RefColors.lime.withValues(alpha: .14),
            border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
            child: const Column(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: RefColors.lime, size: 36),
                SizedBox(height: 10),
                Text(
                  '¡Niebla disipada!',
                  style: TextStyle(
                    color: RefColors.lime,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Recitaste el texto de memoria de forma offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RefColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else ...[
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final double scale = 1 + (_pulse.value * 0.04);
                return Transform.scale(
                  scale: _listening ? scale : 1.0,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _listening ? RefColors.primary : null,
                      color: _listening ? null : RefColors.glassStrong,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _listening
                            ? RefColors.pink
                            : RefColors.border,
                      ),
                      boxShadow: _listening
                          ? [
                              BoxShadow(
                                color: RefColors.pink.withValues(alpha: .25),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _listening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _listening ? 'Detener y Procesar' : 'Recitar con tu voz',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _status.contains('muy baja') ? RefColors.urgent : RefColors.dim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_recognized.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Entendido: "$_recognized"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
