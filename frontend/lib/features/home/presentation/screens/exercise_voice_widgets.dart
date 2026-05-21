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

class _ReadAloudPracticeCardState extends State<_ReadAloudPracticeCard> {
  static const _passScore = .60;
  late final stt.SpeechToText _speech;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  /// Texto reconocido en la sesión ACTUAL de _speech.listen() (Android reinicia
  /// la sesión cada vez que detecta una pausa larga).
  String _recognized = '';
  /// Texto acumulado entre auto-restarts. Cuando STT cierra por pausa y
  /// reabrimos, los nuevos resultados se concatenan acá.
  String _accumulated = '';
  String _status = 'Toca el micrófono y lee el texto.';
  double _score = 0;
  final _audioRecorder = AudioRecorder();
  String? _recordedPath;
  /// `true` cuando el usuario tocó el botón "Detener". Cuando STT cierra por
  /// pausa interna (status=done) y este flag es false, reabrimos automatic.
  bool _userStopRequested = false;
  bool _restartPending = false;
  /// Controla el scroll interno del target text (versos para leer).
  final _targetScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      debugLogging: true,
      onStatus: _handleStatus,
      onError: (error) {
        if (!mounted) return;
        debugPrint('STT error: ${error.errorMsg} permanent=${error.permanent}');
        // Android dispara `error_speech_timeout` / `error_no_match` cuando
        // el usuario hace una pausa breve. NO son errores fatales — el
        // recognizer se cerró y queremos reabrirlo automáticamente (igual
        // que cuando llega status='done'). Solo errores REALMENTE permanentes
        // (mic no disponible, permiso denegado, etc.) deben matar la sesión.
        final recoverable = error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'error_no_speech';
        if (recoverable && !_userStopRequested && _listening) {
          if (_restartPending) return;
          _restartPending = true;
          Future.delayed(const Duration(milliseconds: 250), () {
            _restartPending = false;
            if (!mounted || _userStopRequested) return;
            _restartListenSession();
          });
          return;
        }
        setState(() {
          _listening = false;
          _status = 'STT: ${error.errorMsg}. Intenta otra vez.';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _ready = available;
      _status = available
          ? 'Toca el micrófono y lee el texto.'
          : 'Speech-to-text no disponible. Verifica que el reconocedor de '
                'voz del sistema esté instalado (Google app / Speech Services).';
    });
  }

  /// Elige un locale español disponible en el dispositivo, con fallback al
  /// default. Algunos dispositivos Android solo traen 'es-US' o 'es-419', no
  /// 'es-ES', y la llamada falla silenciosa.
  Future<String> _resolveSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      for (final wanted in ['es_ES', 'es-ES', 'es_MX', 'es-MX', 'es_US', 'es-US', 'es_419', 'es-419']) {
        final match = locales.firstWhere(
          (l) => l.localeId.replaceAll('-', '_') == wanted.replaceAll('-', '_'),
          orElse: () => stt.LocaleName('', ''),
        );
        if (match.localeId.isNotEmpty) return match.localeId;
      }
      // Cualquier locale 'es*' como último recurso.
      final anyEs = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('es'),
        orElse: () => stt.LocaleName('', ''),
      );
      if (anyEs.localeId.isNotEmpty) return anyEs.localeId;
    } catch (e) {
      debugPrint('STT locales lookup failed: $e');
    }
    return 'es_ES';
  }

  @override
  void dispose() {
    _speech.cancel();
    _targetScrollCtrl.dispose();
    _audioRecorder.stop().then((_) => _audioRecorder.dispose());
    super.dispose();
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      // Android cierra la sesión apenas detecta una pausa breve. Si el
      // usuario NO tocó detener, reabrimos automáticamente para que pueda
      // seguir hablando sin perder el flujo.
      if (!_userStopRequested && _listening) {
        if (_restartPending) return;
        _restartPending = true;
        // Pequeño delay para que el recognizer libere recursos antes de
        // reabrir, sino vuelve a fallar.
        Future.delayed(const Duration(milliseconds: 250), () {
          _restartPending = false;
          if (!mounted || _userStopRequested) return;
          _restartListenSession();
        });
        return;
      }
      _finishCapture();
    }
  }

  /// Reabre una sesión de _speech.listen sin resetear el estado UI ni el
  /// texto acumulado. Acumula el último resultado parcial antes de reabrir
  /// para no perder lo que ya leyó.
  Future<void> _restartListenSession() async {
    if (!mounted || !_listening) return;
    // Preserva lo reconocido hasta aquí para concatenar al volver.
    if (_recognized.trim().isNotEmpty) {
      _accumulated = _accumulated.isEmpty
          ? _recognized.trim()
          : '${_accumulated.trim()} ${_recognized.trim()}';
      _recognized = '';
    }
    setState(() {
      _status = 'Escuchando... continúa leyendo cuando quieras.';
    });
    try {
      final localeId = await _resolveSpanishLocale();
      debugPrint('STT auto-restart with locale=$localeId');
      await _speech.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 30),
        onResult: _handleResult,
      );
    } catch (e) {
      debugPrint('STT auto-restart error: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initSpeech();
      return;
    }
    if (_listening) {
      // User tapped stop — flag para que `_handleStatus` no reabra y cierra.
      _userStopRequested = true;
      await _speech.stop();
      _finishCapture();
      return;
    }
    setState(() {
      _recognized = '';
      _accumulated = '';
      _userStopRequested = false;
      _score = 0;
      _completed = false;
      _listening = true;
      _status = 'Escuchando... lee el texto completo.';
    });

    // Start the file recorder FIRST so the first words make it onto disk.
    // En iOS el audio session SE COMPARTE entre `record` y `speech_to_text`
    // (ambos tappean AVAudioEngine sin chocarse). En Android NO: `record`
    // toma exclusivo el MIC y SpeechRecognizer recibe silencio → error
    // `error_speech_timeout`. Por eso saltamos la grabación en Android y
    // dejamos que STT tenga el mic en exclusiva. El replay en
    // `04-escuchar-voz` cae a TTS del texto reconocido.
    if (!Platform.isAndroid) {
      try {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          _recordedPath = path;
        }
      } catch (e) {
        debugPrint('Audio Recorder Error: $e');
      }
    } else {
      _recordedPath = null;
    }

    // Tiny breath so AVAudioSession is fully alive before SFSpeech attaches.
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      final localeId = await _resolveSpanishLocale();
      debugPrint('STT listen with locale=$localeId');
      await _speech.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 30),
        onResult: _handleResult,
      );
    } catch (e) {
      debugPrint('STT Listen Error: $e');
      if (mounted) {
        setState(() {
          _listening = false;
          _status = 'No pude iniciar el reconocimiento. ($e)';
        });
      }
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    final fullText = _accumulated.isEmpty
        ? recognized
        : '${_accumulated.trim()} ${recognized.trim()}';
    final score = _speechSimilarity(fullText, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _recognized = recognized;
      _score = score;
      if (passed) {
        _completed = true;
        _status = 'Vas bien — sigue leyendo o toca detener para guardar.';
      }
    });
    // Auto-scroll perezoso del target text — solo cuando el progreso de
    // reconocimiento (palabras dichas / palabras esperadas) llega al 70%
    // del viewport interno.
    _maybeAutoScrollTarget(fullText);
  }

  /// Scroll perezoso del target text basado en cuántas palabras del target
  /// ya fueron reconocidas. Mismo patrón threshold-70% que usamos en lectura
  /// fragmentada y en audio playback.
  void _maybeAutoScrollTarget(String recognizedFull) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_targetScrollCtrl.hasClients) return;
      final pos = _targetScrollCtrl.position;
      final max = pos.maxScrollExtent;
      if (max <= 0) return;
      final viewport = pos.viewportDimension;
      final spoken = _speechSimilarity(recognizedFull, widget.targetText);
      // `spoken` es el ratio de similitud — proxy aceptable de "cuánto del
      // target ya pasó el usuario leyendo".
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
    try {
      // Solo iOS arrancó el recorder; en Android nunca lo iniciamos.
      if (!Platform.isAndroid) {
        final path = await _audioRecorder.stop();
        if (path != null) _recordedPath = path;
      }
      if (!mounted) return;
      setState(() => _listening = false);
      // Texto total reconocido = acumulado de sesiones previas + última.
      final fullText = _accumulated.isEmpty
          ? _recognized
          : '${_accumulated.trim()} ${_recognized.trim()}';
      _grade(fullText);
    } finally {
      _finalizing = false;
    }
  }

  void _grade(String recognized) {
    final score = _speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _score = score;
      _completed = passed;
      _status = passed
          ? '60% o más está fino. Puedes avanzar.'
          : 'Se parece poco todavía. Reintenta leyendo más completo.';
    });
    if (passed) widget.onCompleted(recognized, _recordedPath);
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
              // height fijo. Auto-scrollea perezosamente conforme el STT
              // va reconociendo palabras — solo cuando la palabra activa
              // pasa del 70% del viewport interno.
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
              const SizedBox(height: 16),
              // Mic + score DEBAJO del texto a leer — siempre visible.
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: _listening ? RefColors.primary : null,
                        color: _listening ? null : RefColors.glassStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: RefColors.border),
                      ),
                      child: Icon(
                        _listening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          _status,
                          style: const TextStyle(
                            color: RefColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Caja de texto reconocido — debajo del mic, todavía a la
              // vista al arrancar a leer.
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: Text(
                  _recognized.isEmpty
                      ? 'Aquí aparecerá lo que entendió el reconocimiento de voz.'
                      : _recognized,
                  style: TextStyle(
                    color: _recognized.isEmpty ? RefColors.dim : RefColors.ink,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
  int _highlightedCount = 0;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _audioPlayer = AudioPlayer();

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
        setState(() {
          _highlightedCount = (progress * _currentText.length).toInt().clamp(
            0,
            _currentText.length,
          );
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _highlightedCount = 0;
        if (_tab == 1) _completed = true;
      });
      if (_tab == 1) widget.onCompleted();
    });

    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (mounted) {
        setState(() {
          _highlightedCount = end.clamp(0, _currentText.length);
        });
      }
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _highlightedCount = 0;
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
          _highlightedCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
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
          _highlightedCount = 0;
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
      _highlightedCount = 0;
    });
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
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: _tab == 1 && !hasVoice
                      ? RefColors.dim
                      : RefColors.ink.withValues(alpha: 0.4),
                  fontSize: 18,
                  height: 1.38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
                children: [
                  if (_highlightedCount > 0)
                    TextSpan(
                      text: _currentText.substring(0, _highlightedCount),
                      style: const TextStyle(color: RefColors.ink),
                    ),
                  TextSpan(text: _currentText.substring(_highlightedCount)),
                ],
              ),
            ),
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

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });
    _tts.setCompletionHandler(() {
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

  @override
  void dispose() {
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
    final nextIndex = (_wordIndex + 12).clamp(0, words.length - 1);
    await _tts.stop();
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

