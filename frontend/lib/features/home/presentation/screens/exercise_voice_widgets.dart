// AUTO-GENERATED extraction from ui_screens.dart (refactor PR-D).
// Tightly-coupled exercise-flow widgets — kept in this library to
// preserve cross-class private visibility.
part of '../ui_screens.dart';

class _ReadAloudPracticeCard extends StatefulWidget {
  final String targetText;
  final String source;
  final void Function(String text, String? audioPath) onCompleted;

  const _ReadAloudPracticeCard({
    required this.targetText,
    required this.source,
    required this.onCompleted,
  });

  @override
  State<_ReadAloudPracticeCard> createState() => _ReadAloudPracticeCardState();
}

class _ReadAloudPracticeCardState extends State<_ReadAloudPracticeCard>
    with SingleTickerProviderStateMixin {
  static const _passScore = .60;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  
  bool _isModelDownloaded = false;
  bool _isDownloadingModel = false;
  bool _isModelInitializing = false;
  double _modelDownloadProgress = 0.0;
  String _modelStatus = '';

  /// Texto reconocido real por Whisper.
  String _recognized = '';
  /// Texto acumulado.
  String _accumulated = '';
  String _status = 'Toca el micrófono y lee el texto.';
  double _score = 0;
  final _audioRecorder = AudioRecorder();
  String? _recordedPath;
  Timer? _autoStopTimer;
  /// Controla el scroll interno del target text (versos para leer).
  final _targetScrollCtrl = ScrollController();
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _checkModelStatus();
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
            ? 'Toca el micrófono y lee el texto de corrido.'
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
    _targetScrollCtrl.dispose();
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
      _accumulated = '';
      _score = 0;
      _completed = false;
      _listening = true;
      _status = 'Grabando... lee el texto completo sin interrupciones.';
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
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.raw';
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

  void _maybeAutoScrollTarget(String recognizedFull) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_targetScrollCtrl.hasClients) return;
      final pos = _targetScrollCtrl.position;
      final max = pos.maxScrollExtent;
      if (max <= 0) return;
      final viewport = pos.viewportDimension;
      final spoken = _speechSimilarity(recognizedFull, widget.targetText);
      final totalContentHeight = max + viewport;
      final progressY = totalContentHeight * spoken.clamp(0.0, 1.0);
      final thresholdY = pos.pixels + viewport * 0.70;
      if (progressY < thresholdY) return;
      final target = (progressY - viewport * 0.60).clamp(0.0, max);
      if (target <= pos.pixels) return;
      _targetScrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _finalizing = false;
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
        _status = 'Analizando tu voz...';
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
      debugPrint('Error al detener/transcribir la grabación: $e');
      if (mounted) {
        setState(() {
          _status = 'Error en reconocimiento local: $e';
        });
      }
    } finally {
      _finalizing = false;
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

    // "RIFF"
    header[0] = 82; // R
    header[1] = 73; // I
    header[2] = 70; // F
    header[3] = 70; // F

    // Chunk Size (file length - 8)
    data.setUint32(4, dataLength + 36, Endian.little);

    // "WAVE"
    header[8] = 87;  // W
    header[9] = 65;  // A
    header[10] = 86; // V
    header[11] = 69; // E

    // "fmt "
    header[12] = 102; // f
    header[13] = 109; // m
    header[14] = 116; // t
    header[15] = 32;  //  

    // Subchunk 1 Size (16)
    data.setUint32(16, 16, Endian.little);

    // Audio Format (1 = PCM)
    data.setUint16(20, 1, Endian.little);

    // Num Channels (1 = Mono)
    data.setUint16(22, 1, Endian.little);

    // Sample Rate (16000)
    data.setUint32(24, 16000, Endian.little);

    // Byte Rate (SampleRate * NumChannels * BitsPerSample/8 = 16000 * 1 * 16/8 = 32000)
    data.setUint32(28, 32000, Endian.little);

    // Block Align (NumChannels * BitsPerSample/8 = 2)
    data.setUint16(32, 2, Endian.little);

    // Bits Per Sample (16)
    data.setUint16(34, 16, Endian.little);

    // "data"
    header[36] = 100; // d
    header[37] = 97;  // a
    header[38] = 116; // t
    header[39] = 97;  // a

    // Subchunk 2 Size (data length)
    data.setUint32(40, dataLength, Endian.little);

    return header;
  }

  void _gradeReal(String text) {
    if (!mounted) return;
    final score = _speechSimilarity(text, widget.targetText);
    final passed = score >= _passScore;
    setState(() {
      _score = score;
      _completed = passed;
      _recognized = text;
      _status = passed 
          ? 'Lectura completada y guardada con éxito.' 
          : 'La similitud es muy baja (${(score * 100).round()}%). Lee de nuevo con claridad.';
    });
    
    _maybeAutoScrollTarget(text);

    if (passed) {
      widget.onCompleted(text, _recordedPath);
    }
  }

  /// Renderiza el target verso-por-verso si la sesión es batched. Si es 1
  /// solo item, vuelve al render plano (un solo Text con todo el back).
  List<Widget> _buildVersedDisplay(BuildContext context) {
    final verses = _currentBatchVerses(context);
    const style = TextStyle(
      fontSize: 20,
      height: 1.36,
      fontWeight: FontWeight.w900,
      color: RefColors.ink,
    );
    if (verses.length == 1) {
      return [Text(verses.first.text, style: style)];
    }
    return [
      for (var i = 0; i < verses.length; i++) ...[
        _VerseLine(
          number: verses[i].number,
          words: _studyWords(verses[i].text),
          defaultStyle: style,
          fontSize: 20,
        ),
        if (i < verses.length - 1) const SizedBox(height: 10),
      ],
    ];
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Glass(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RefColors.violet.withValues(alpha: .18),
                RefColors.cyan.withValues(alpha: .06),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Badge de Componente del Sistema
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RefColors.cyan.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: RefColors.cyan.withValues(alpha: .25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: RefColors.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'COMPONENTE DE SISTEMA',
                        style: TextStyle(
                          color: RefColors.cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Icono Central tipo Chip de IA
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: RefColors.violet.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: RefColors.violet.withValues(alpha: .20),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    color: RefColors.cyan,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                
                const Text(
                  'Motor de Voz de Alta Precisión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RefColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Descarga el componente de voz (375 MB) para recitar tus versos offline con total privacidad y seguridad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_isDownloadingModel || _isModelInitializing) ...[
                  Text(
                    _isModelInitializing
                        ? 'Configurando módulo...'
                        : 'Preparando motor: $downloadPercent%',
                    style: const TextStyle(
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
                    style: const TextStyle(
                      color: RefColors.dim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  // Botón de activación nativa
                  GestureDetector(
                    onTap: _downloadModels,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: RefColors.cool,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: RefColors.cyan.withValues(alpha: .20),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Activar Reconocimiento de Voz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Fichas técnicas sutiles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sd_storage_outlined, size: 12, color: RefColors.dim),
                      const SizedBox(width: 4),
                      Text(
                        'Componente: 375 MB',
                        style: TextStyle(
                          color: RefColors.dim,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.shield_outlined, size: 12, color: RefColors.dim),
                      const SizedBox(width: 4),
                      Text(
                        '100% Seguro y Privado',
                        style: TextStyle(
                          color: RefColors.dim,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final percent = (_score * 100).round();
    final accent = _completed
        ? RefColors.lime
        : _score >= .45
        ? RefColors.sun
        : RefColors.pink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          gradient: LinearGradient(
            colors: [
              RefColors.violet.withValues(alpha: .24),
              RefColors.cyan.withValues(alpha: .10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.source,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Target text ARRIBA en un contenedor scrollable con max
              // height fijo.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  controller: _targetScrollCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildVersedDisplay(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Mic + score/ondas DEBAJO del texto a leer.
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_listening)
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, _) {
                                final t = _pulse.value;
                                return Container(
                                  width: 56 + 14 * t,
                                  height: 56 + 14 * t,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: RefColors.cyan.withValues(alpha: 1 - t),
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: RefColors.cyan.withValues(
                                alpha: _listening ? .55 : .18,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: RefColors.cyan.withValues(alpha: .85)),
                              boxShadow: [
                                BoxShadow(
                                  color: RefColors.cyan.withValues(alpha: .35),
                                  blurRadius: _listening ? 28 : 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              _listening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: RefColors.ink,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_listening) ...[
                          const Text(
                            'Grabando voz...',
                            style: TextStyle(
                              color: RefColors.cyan,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ] else ...[
                          if (_score > 0) ...[
                            Text(
                              '$percent% parecido',
                              style: TextStyle(
                                color: accent,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            RefProgress(_score.clamp(.02, 1.0)),
                            const SizedBox(height: 7),
                          ],
                          Text(
                            _status,
                            style: TextStyle(
                              color: _score > 0 ? RefColors.muted : RefColors.dim,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_listening) ...[
                const SizedBox(height: 24),
                // Panel flotante animado de ondas de voz en tiempo real
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: RefColors.cyan.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: RefColors.cyan.withValues(alpha: .15),
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      _ListeningWaveIndicator(color: RefColors.cyan),
                    ],
                  ),
                ),
              ],

              // Caja de texto reconocido — solo al final cuando no esté grabando y tenga texto
              if (!_listening && _recognized.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: HtmlRefColors.glassSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HtmlRefColors.glassBorder),
                  ),
                  child: Builder(
                    builder: (context) {
                      final fullTextToShow = _accumulated.isEmpty
                          ? _recognized
                          : '${_accumulated.trim()} ${_recognized.trim()}';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.translate_rounded, size: 12, color: RefColors.cyan),
                              SizedBox(width: 6),
                              Text(
                                'TEXTO DETECTADO',
                                style: TextStyle(
                                  color: RefColors.cyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fullTextToShow,
                            style: const TextStyle(
                              color: RefColors.ink,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Widget premium de ondas de voz animadas
class _ListeningWaveIndicator extends StatefulWidget {
  final Color color;
  const _ListeningWaveIndicator({this.color = RefColors.cyan});

  @override
  State<_ListeningWaveIndicator> createState() => _ListeningWaveIndicatorState();
}

class _ListeningWaveIndicatorState extends State<_ListeningWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(6, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final wave = math.sin((_controller.value * 2 * math.pi) - (index * 0.6));
              final height = 12.0 + (wave.abs() * 32.0);
              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color,
                      RefColors.violet,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: .25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _ListenOwnVoicePracticeCard extends StatefulWidget {
  final String originalText;
  final String voiceText;
  final String source;
  final String? audioPath;
  final VoidCallback onCompleted;

  const _ListenOwnVoicePracticeCard({
    required this.originalText,
    required this.voiceText,
    required this.source,
    this.audioPath,
    required this.onCompleted,
  });

  @override
  State<_ListenOwnVoicePracticeCard> createState() =>
      _ListenOwnVoicePracticeCardState();
}

class _ListenOwnVoicePracticeCardState
    extends State<_ListenOwnVoicePracticeCard> {
  late final FlutterTts _tts;
  late final AudioPlayer _audioPlayer;
  int _tab = 1;
  bool _playing = false;
  bool _completed = false;
  int _wordIndex = 0;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _audioPlayer = AudioPlayer();
    ActiveMediaRegistry.register(stopPlayback);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playing = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _audioDuration.inMilliseconds > 0 && _playing) {
        final progress =
            position.inMilliseconds / _audioDuration.inMilliseconds;
        final words = _studyWords(_currentText);
        setState(() {
          _wordIndex = (progress * words.length).toInt().clamp(0, words.length);
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _wordIndex = 0;
        if (_tab == 1) _completed = true;
      });
      if (_tab == 1) widget.onCompleted();
    });

    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (mounted) {
        final textBefore = _currentText.substring(0, end);
        setState(() {
          _wordIndex = _studyWords(textBefore).length;
        });
      }
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _wordIndex = 0;
        if (_tab == 1 && widget.voiceText.trim().isNotEmpty) {
          _completed = true;
        }
      });
      if (_tab == 1 && widget.voiceText.trim().isNotEmpty) {
        widget.onCompleted();
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _playing = false;
          _wordIndex = 0;
        });
      }
    });
  }

  void stopPlayback() {
    _tts.stop();
    _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _playing = false;
        _wordIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    ActiveMediaRegistry.unregister(stopPlayback);
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _currentText {
    if (_tab == 1 && widget.voiceText.trim().isEmpty) {
      return 'Primero completa el paso de leer en voz para guardar tu lectura.';
    }
    return widget.originalText;
  }

  Future<void> _play() async {
    if (_playing) {
      await _tts.stop();
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _playing = false;
          _wordIndex = 0;
        });
      }
      return;
    }

    if (_tab == 1 && widget.audioPath != null) {
      await _audioPlayer.setPlaybackRate(1);
      await _audioPlayer.play(DeviceFileSource(widget.audioPath!));
      final duration = await _audioPlayer.getDuration();
      if (mounted && duration != null) {
        setState(() => _audioDuration = duration);
      }
    } else {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(_tab == 0 ? 0.44 : 0.48);
      await _tts.setPitch(_tab == 0 ? 1.0 : .92);
      await _tts.speak(_currentText);
    }
  }

  Future<void> _switchTab(int tab) async {
    await _tts.stop();
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _tab = tab;
      _playing = false;
      _wordIndex = 0;
    });
  }

  Widget _buildVersedText(BuildContext context, int globalIndex) {
    final hasVoice = widget.voiceText.trim().isNotEmpty;
    if (_tab == 1 && !hasVoice) {
      return const Text(
        'Primero completa el paso de leer en voz para guardar tu lectura.',
        style: TextStyle(
          color: RefColors.dim,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontFamily: 'Outfit',
        ),
      );
    }

    final verses = _currentBatchVerses(context);
    if (verses.length == 1) {
      final words = _studyWords(verses.first.text);
      final safe = globalIndex.clamp(0, words.isEmpty ? 0 : words.length - 1);
      final lead = words.take(safe).join(' ');
      final current = words.isEmpty ? '' : words[safe];
      final tail = words.isEmpty ? '' : words.skip(safe + 1).join(' ');
      return Text.rich(
        TextSpan(
          children: [
            if (lead.isNotEmpty)
              TextSpan(
                text: '$lead ',
                style: const TextStyle(color: RefColors.lime),
              ),
            if (current.isNotEmpty)
              TextSpan(
                text: current,
                style: const TextStyle(
                  color: RefColors.ink,
                  backgroundColor: Color(0x44273CFE),
                ),
              ),
            if (tail.isNotEmpty)
              TextSpan(
                text: ' $tail',
                style: const TextStyle(color: RefColors.muted),
              ),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          height: 1.38,
          fontWeight: FontWeight.w900,
          fontFamily: 'Outfit',
        ),
      );
    }

    int? activeVerse;
    int? activeLocal;
    var offset = 0;
    for (var i = 0; i < verses.length; i++) {
      final n = _studyWords(verses[i].text).length;
      if (globalIndex >= offset && globalIndex < offset + n) {
        activeVerse = i;
        activeLocal = globalIndex - offset;
        break;
      }
      offset += n;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < verses.length; i++) ...[
          _VerseLine(
            number: verses[i].number,
            words: _studyWords(verses[i].text),
            defaultStyle: const TextStyle(
              color: RefColors.muted,
              fontWeight: FontWeight.w900,
              height: 1.38,
              fontFamily: 'Outfit',
            ),
            wordStyle: (idx) {
              if (activeVerse != null && i < activeVerse) {
                return const TextStyle(
                  color: RefColors.lime,
                  fontWeight: FontWeight.w900,
                );
              }
              if (i == activeVerse) {
                if (idx < (activeLocal ?? 0)) {
                  return const TextStyle(
                    color: RefColors.lime,
                    fontWeight: FontWeight.w900,
                  );
                }
                if (idx == activeLocal) {
                  return const TextStyle(
                    color: RefColors.ink,
                    fontWeight: FontWeight.w900,
                    backgroundColor: Color(0x44273CFE),
                  );
                }
                return const TextStyle(
                  color: RefColors.muted,
                  fontWeight: FontWeight.w900,
                );
              }
              return null;
            },
            fontSize: 18,
          ),
          if (i < verses.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = widget.voiceText.trim().isNotEmpty;
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .25),
          RefColors.sun.withValues(alpha: .16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VoiceTab(
                    'Tuyo',
                    active: _tab == 1,
                    onTap: () => _switchTab(1),
                  ),
                  const SizedBox(width: 4),
                  _VoiceTab(
                    'Original',
                    active: _tab == 0,
                    onTap: () => _switchTab(0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.source,
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 138),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HtmlRefColors.glassBorder),
            ),
            child: _buildVersedText(context, _wordIndex),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PlayerMainButton(paused: _playing, onTap: _play),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _tab == 0
                      ? 'Escucha el original para comparar.'
                      : hasVoice
                      ? (_completed
                            ? 'Ya escuchaste tu lectura. Puedes avanzar.'
                            : 'Reproduce tu lectura para cerrar el paso.')
                      : 'No hay lectura guardada todavía.',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VoiceTab(this.label, {required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? RefColors.primary : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : RefColors.muted,
          ),
        ),
      ),
    );
  }
}

class _ListenAudioCard extends StatefulWidget {
  final VoidCallback? onCompleted;

  const _ListenAudioCard({this.onCompleted});

  @override
  State<_ListenAudioCard> createState() => _ListenAudioCardState();
}

class _ListenAudioCardState extends State<_ListenAudioCard> {
  late final FlutterTts _tts;
  final ScrollController _textScrollController = ScrollController();
  bool _playing = false;
  bool _completed = false;
  int _wordIndex = 0;
  int _ttsStartWordOffset = 0;
  int _lastSkipTime = 0;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    ActiveMediaRegistry.register(stopPlayback);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });
    _tts.setCompletionHandler(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastSkipTime < 600) {
        return;
      }
      if (mounted) {
        setState(() {
          _playing = false;
          _completed = true;
          _wordIndex = 0;
        });
        widget.onCompleted?.call();
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _playing = false);
    });
    _tts.setProgressHandler((text, startOffset, endOffset, word) {
      if (!mounted) return;
      final before = text.substring(0, startOffset.clamp(0, text.length));
      final index = _studyWords(
        before,
      ).length.clamp(0, _studyWords(text).length);
      final absoluteIndex = (_ttsStartWordOffset + index).clamp(
        0,
        _studyWords(_cardStudyText(context)).length,
      );
      setState(() => _wordIndex = absoluteIndex);
      _scrollToProgress(
        absoluteIndex,
        _studyWords(_cardStudyText(context)).length,
      );
    });
  }

  void stopPlayback() {
    _tts.stop();
    if (mounted) {
      setState(() {
        _playing = false;
        _wordIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    ActiveMediaRegistry.unregister(stopPlayback);
    _tts.stop();
    _textScrollController.dispose();
    super.dispose();
  }

  /// Scroll perezoso — antes movía un poquito por cada palabra (terremoto
  /// visual). Ahora solo mueve cuando la palabra actual cae por debajo del
  /// 70% del viewport, y lo lleva al ~50% para dejar contexto arriba/abajo.
  void _scrollToProgress(int index, int total) {
    if (total <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_textScrollController.hasClients) return;
      final pos = _textScrollController.position;
      final max = pos.maxScrollExtent;
      if (max <= 0) return;
      final viewport = pos.viewportDimension;
      final ratio = (index / (total - 1)).clamp(0.0, 1.0);
      final totalContentHeight = max + viewport;
      final currentWordY = totalContentHeight * ratio;
      // Trigger solo si la palabra activa sobrepasó el 70% del viewport
      // visible o ya salió por abajo.
      final thresholdY = pos.pixels + viewport * 0.70;
      if (currentWordY < thresholdY) return;
      final target = (currentWordY - viewport * 0.50).clamp(0.0, max);
      if (target <= pos.pixels) return;
      _textScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _toggle(String text) async {
    if (_playing) {
      await _tts.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.44);
    await _tts.setPitch(1.0);
    await _speakFromCurrent(text);
  }

  Future<void> _restart(String text) async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _wordIndex = 0;
        _playing = false;
        _completed = false;
      });
    }
    await _toggle(text);
  }

  Future<void> _speakFromCurrent(String text) async {
    final words = _studyWords(text);
    final start = _wordIndex.clamp(0, words.length - 1);
    _ttsStartWordOffset = start;
    final remaining = words.skip(start).join(' ');
    await _tts.speak(remaining);
  }

  Future<void> _skipForward(String text) async {
    final words = _studyWords(text);
    final nextIndex = _wordIndex + 12;
    
    _lastSkipTime = DateTime.now().millisecondsSinceEpoch;
    await _tts.stop();
    
    if (nextIndex >= words.length) {
      if (mounted) {
        setState(() {
          _wordIndex = 0;
          _playing = false;
          _completed = true;
        });
        widget.onCompleted?.call();
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _wordIndex = nextIndex;
        _playing = false;
      });
    }
    _scrollToProgress(nextIndex, words.length);
    await _toggle(text);
  }

  /// Renderiza el texto del paso Escuchar verso-por-verso (cuando el grupo
  /// tiene 2+ versos). El índice global apunta a la palabra que TTS está
  /// leyendo en este momento — se traduce a (verso, palabra local) para
  /// resaltarla solo en su verso. Si solo hay 1 verso, vuelve al render
  /// linear con lead/current/tail.
  Widget _buildVersedListenText(BuildContext context, int globalIndex) {
    final verses = _currentBatchVerses(context);
    if (verses.length == 1) {
      // Single-item: render plano como antes (lead + highlight + tail).
      final words = _studyWords(verses.first.text);
      final safe = globalIndex.clamp(0, words.length - 1);
      final lead = words.take(safe).join(' ');
      final current = words.isEmpty ? '' : words[safe];
      final tail = words.skip(safe + 1).join(' ');
      return Text.rich(
        TextSpan(
          children: [
            if (lead.isNotEmpty)
              TextSpan(
                text: '$lead ',
                style: const TextStyle(color: RefColors.lime),
              ),
            TextSpan(
              text: current,
              style: const TextStyle(
                color: RefColors.ink,
                backgroundColor: Color(0x44273CFE),
              ),
            ),
            TextSpan(
              text: tail.isEmpty ? '' : ' $tail',
              style: const TextStyle(color: RefColors.muted),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          height: 1.34,
          fontWeight: FontWeight.w900,
          letterSpacing: -.35,
        ),
      );
    }
    // Múltiples versos: encontrar a qué verso pertenece globalIndex.
    // El back combinado es "1 verse1 2 verse2 3 verse3"; cada verso aporta
    // 1 (el número) + N_i palabras al índice global.
    int? activeVerse;
    int? activeLocal;
    var offset = 0;
    for (var i = 0; i < verses.length; i++) {
      final n = _studyWords(verses[i].text).length;
      // El número ocupa el slot `offset`; las palabras del verso van
      // de `offset+1` a `offset+n`.
      if (globalIndex >= offset && globalIndex <= offset + n) {
        if (globalIndex == offset) {
          activeVerse = i;
          activeLocal = -1; // el número del verso está activo
        } else {
          activeVerse = i;
          activeLocal = globalIndex - offset - 1;
        }
        break;
      }
      offset += 1 + n;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < verses.length; i++) ...[
          _VerseLine(
            number: verses[i].number,
            words: _studyWords(verses[i].text),
            defaultStyle: const TextStyle(
              color: RefColors.muted,
              fontWeight: FontWeight.w900,
              height: 1.32,
            ),
            wordStyle: (idx) {
              // Verso entero "ya leído": lime suave.
              if (activeVerse != null && i < activeVerse!) {
                return const TextStyle(
                  color: RefColors.lime,
                  fontWeight: FontWeight.w900,
                );
              }
              // Verso activo: lead lime, current highlight, tail muted.
              if (i == activeVerse) {
                if (idx < (activeLocal ?? -1)) {
                  return const TextStyle(
                    color: RefColors.lime,
                    fontWeight: FontWeight.w900,
                  );
                }
                if (idx == activeLocal) {
                  return const TextStyle(
                    color: RefColors.ink,
                    fontWeight: FontWeight.w900,
                    backgroundColor: Color(0x44273CFE),
                  );
                }
                return const TextStyle(
                  color: RefColors.muted,
                  fontWeight: FontWeight.w900,
                );
              }
              return null; // verso futuro → defaultStyle (muted)
            },
            fontSize: 22,
          ),
          if (i < verses.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final source = _cardSourceText(context).toUpperCase();
    final text = _cardStudyText(context);
    final safeIndex = _wordIndex.clamp(0, words.isEmpty ? 0 : words.length - 1);
    final progress = words.isEmpty ? 0.0 : ((safeIndex + 1) / words.length);
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .34),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Text(
            source,
            style: TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 34),
          Expanded(
            child: Scrollbar(
              controller: _textScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _textScrollController,
                padding: const EdgeInsets.only(right: 10),
                child: _buildVersedListenText(context, safeIndex),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: RefProgress(progress.clamp(.03, 1.0)),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                _playing ? 'Leyendo' : 'Listo',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${safeIndex + 1}/${words.length} palabras',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerSmallButton(
                Icons.replay_rounded,
                onTap: () => _restart(text),
              ),
              const SizedBox(width: 18),
              _PlayerMainButton(paused: _playing, onTap: () => _toggle(text)),
              const SizedBox(width: 18),
              _PlayerSmallButton(
                Icons.forward_5_rounded,
                onTap: () => _skipForward(text),
              ),
            ],
          ),
          if (_completed) ...[
            const SizedBox(height: 12),
            const StatusChip(
              'ESCUCHA COMPLETA',
              color: Color(0x338DFD63),
              borderColor: Color(0x668DFD63),
              textColor: RefColors.lime,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerSmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PlayerSmallButton(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: RefColors.glassStrong,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RefColors.border),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _PlayerMainButton extends StatelessWidget {
  final bool paused;
  final VoidCallback? onTap;

  const _PlayerMainButton({this.paused = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: RefColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: RefColors.pink.withValues(alpha: .42),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 34,
        ),
      ),
    );
  }
}

class _FlowHintCard extends StatelessWidget {
  final String icon;
  final String text;

  const _FlowHintCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FragmentedTextCard extends StatelessWidget {
  const _FragmentedTextCard();

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final visible = words.take(3).join(' ');
    final active = words.length > 3 ? words[3] : '';
    final hidden = words.skip(4).join(' ');
    final activeSplit = active.length < 2 ? active.length : 2;
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: SizedBox(
        height: 150,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$visible '),
                TextSpan(
                  text: active.isEmpty ? '' : active.substring(0, activeSplit),
                  style: const TextStyle(
                    color: RefColors.ink,
                    decoration: TextDecoration.underline,
                    decorationColor: RefColors.pink,
                    decorationThickness: 3,
                  ),
                ),
                TextSpan(
                  text: active.isEmpty
                      ? hidden
                      : '${active.substring(activeSplit)} $hidden',
                  style: const TextStyle(color: RefColors.dim),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 29,
              height: 1.45,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedSelectorCard extends StatelessWidget {
  const _SpeedSelectorCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            'VELOCIDAD',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _SpeedPill('Lenta')),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Normal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Expanded(child: _SpeedPill('Rápida')),
        ],
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  final String label;

  const _SpeedPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: RefColors.glassSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RefColors.border),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TapPauseCard extends StatelessWidget {
  const _TapPauseCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.cyan.withValues(alpha: .08),
      border: Border.all(color: RefColors.cyan.withValues(alpha: .28)),
      child: Row(
        children: [
          const Text('👆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Toca la pantalla para pausar · desliza → para saltar al final',
              style: TextStyle(
                color: RefColors.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: RefColors.cyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '⏸ Pausar',
              style: TextStyle(
                color: Color(0xFF003A4A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KaraokeLine extends StatelessWidget {
  final double fontSize;

  const _KaraokeLine({this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final lead = words.take(3).join(' ');
    final current = words.length > 3 ? words[3] : words.last;
    final tail = words.skip(4).join(' ');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$lead ',
            style: const TextStyle(color: RefColors.lime),
          ),
          TextSpan(
            text: current,
            style: const TextStyle(
              color: RefColors.ink,
              backgroundColor: Color(0x553B173E),
              decoration: TextDecoration.underline,
              decorationColor: RefColors.pink,
              decorationThickness: 3,
            ),
          ),
          TextSpan(
            text: tail.isEmpty ? '' : ' $tail',
            style: const TextStyle(color: RefColors.muted),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.42,
        fontWeight: FontWeight.w900,
        letterSpacing: -.35,
      ),
    );
  }
}

class _PulseMic extends StatelessWidget {
  const _PulseMic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final size in [150.0, 122.0, 98.0])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RefColors.pink.withValues(alpha: .35),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RefColors.pink.withValues(alpha: .45),
                    blurRadius: 34,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎤', style: TextStyle(fontSize: 36)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceQuoteCard extends StatelessWidget {
  const _VoiceQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .33),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: const _KaraokeLine(fontSize: 22),
    );
  }
}

enum _WaveKind { original, you }

class _WaveformCard extends StatelessWidget {
  final _WaveKind kind;

  const _WaveformCard({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isYou = kind == _WaveKind.you;
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              StatusChip(
                isYou ? 'TÚ' : 'ORIGINAL',
                color: (isYou ? RefColors.pink : RefColors.cyan).withValues(
                  alpha: .18,
                ),
                borderColor: (isYou ? RefColors.pink : RefColors.cyan)
                    .withValues(alpha: .38),
                textColor: isYou ? RefColors.pink : RefColors.cyan,
              ),
              if (isYou) ...[
                const SizedBox(width: 8),
                const StatusChip(
                  '3/5 REP',
                  color: RefColors.glassStrong,
                  textColor: RefColors.pink,
                ),
              ],
              const Spacer(),
              const _SpeedMini('0.5×'),
              const SizedBox(width: 4),
              const _SpeedMini('1×', active: true),
              const SizedBox(width: 4),
              const _SpeedMini('1.5×'),
            ],
          ),
          const SizedBox(height: 14),
          _WaveBars(color: isYou ? RefColors.pink : RefColors.cyan),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                isYou ? '0:01' : '0:00',
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const _PlayerTinyButton(Icons.replay_rounded),
              const SizedBox(width: 10),
              _PlayerRoundButton(paused: isYou),
              const SizedBox(width: 10),
              const _PlayerTinyButton(Icons.replay_rounded, mirror: true),
              const Spacer(),
              const Text(
                '0:04',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedMini extends StatelessWidget {
  final String label;
  final bool active;

  const _SpeedMini(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? null : RefColors.glassStrong,
        gradient: active ? RefColors.primary : null,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: active ? Colors.transparent : RefColors.border,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  final Color color;

  const _WaveBars({required this.color});

  @override
  Widget build(BuildContext context) {
    const heights = [
      24.0,
      40.0,
      30.0,
      52.0,
      34.0,
      44.0,
      25.0,
      38.0,
      48.0,
      31.0,
      42.0,
      29.0,
    ];
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            Expanded(
              child: Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: color.withValues(alpha: i < 6 ? .95 : .55),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < heights.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _PlayerTinyButton extends StatelessWidget {
  final IconData icon;
  final bool mirror;

  const _PlayerTinyButton(this.icon, {this.mirror = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RefColors.border),
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(mirror ? -1.0 : 1.0, 1.0, 1.0),
        child: Icon(icon, size: 19),
      ),
    );
  }
}

class _PlayerRoundButton extends StatelessWidget {
  final bool paused;

  const _PlayerRoundButton({this.paused = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: paused ? 58 : 52,
      height: paused ? 58 : 52,
      decoration: BoxDecoration(
        color: paused ? null : RefColors.glassStrong,
        gradient: paused ? RefColors.primary : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: paused ? Colors.transparent : RefColors.border,
        ),
        boxShadow: paused
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(paused ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

class ActiveMediaRegistry {
  static final List<VoidCallback> _activeStoppers = [];

  static void register(VoidCallback stopCallback) {
    _activeStoppers.add(stopCallback);
  }

  static void unregister(VoidCallback stopCallback) {
    _activeStoppers.remove(stopCallback);
  }

  static void stopAll() {
    for (final stop in List.from(_activeStoppers)) {
      try {
        stop();
      } catch (_) {}
    }
    _activeStoppers.clear();
  }
}

