// Generado del refactor de ui_screens.dart.
// _FogStep — recitación con neblina por NIVEL (1=fácil, 2=medio, 3=duro).
// El usuario debe recitar al menos el 60% del texto con el micrófono;
// puede tocar "Ver" para una vista limpia momentánea.
part of '../ui_screens.dart';

class _FogStep extends StatefulWidget {
  final String targetText;
  /// 1 = blur suave (visible, intro). 2 = medio. 3 = denso (memoria pura).
  final int level;
  final bool finished;
  final VoidCallback onCompleted;

  const _FogStep({
    required this.targetText,
    required this.level,
    required this.finished,
    required this.onCompleted,
  });

  @override
  State<_FogStep> createState() => _FogStepState();
}

class _FogStepState extends State<_FogStep>
    with SingleTickerProviderStateMixin {
  /// Umbral mínimo de palabras recitadas para considerar la ronda aprobada.
  static const _passRatio = 0.60;

  stt.SpeechToText? _speech;
  bool _ready = false;
  bool _listening = false;
  bool _starting = false;
  late AnimationController _pulse;
  late List<String> _allWords;
  /// Texto reconocido en la sesión STT ACTUAL (Android reinicia la sesión
  /// cada vez que detecta una pausa larga).
  String _recognized = '';
  /// Texto acumulado entre auto-restarts del STT. Cuando la sesión se cierra
  /// por pausa y reabrimos, lo reconocido se concatena acá — sin esto, el
  /// progreso se perdía en cada pausa y "el micrófono no avanzaba".
  String _accumulated = '';
  /// Similitud difusa (0..1) del texto recitado contra el objetivo. Misma
  /// métrica que usa el ejercicio de leer en voz alta.
  double _ratio = 0;
  bool _userStopRequested = false;
  bool _restartPending = false;
  /// Mientras es true, el blur se desactiva temporalmente (botón "Ver").
  bool _peeking = false;
  Timer? _peekTimer;
  /// Vista cronometrada inicial / entre rondas — el texto se muestra
  /// totalmente claro por unos segundos antes de aplicar el blur. Cada
  /// nivel define cuántos segundos.
  bool _showingClear = false;
  Timer? _clearViewTimer;
  /// Ronda actual dentro del paso (0..maxRounds-1). El blur se intensifica
  /// con cada ronda; el usuario debe recitar 60% en cada una.
  int _round = 0;
  /// Cuántas veces puede usar el botón "Ver" en esta ronda. Se llena al
  /// pasar de ronda según el nivel.
  int _peeksLeft = 0;
  /// Índices de palabra que están ocultas (con blur) en la ronda actual.
  /// El resto se muestra claro. Cuando el nivel es 3 o se completó la
  /// última ronda, contiene todos los índices.
  Set<int> _hiddenIndexes = <int>{};

  // --- Tablas de configuración por nivel ---------------------------------
  int get _maxRounds {
    switch (widget.level) {
      case 1: return 3;
      case 2: return 2;
      default: return 1;
    }
  }
  int _previewSeconds(int round) {
    if (widget.level == 3) return 0;
    if (widget.level == 2) return round == 0 ? 3 : 1;
    return round == 0 ? 5 : 2; // N1
  }
  int _peeksAtStart() {
    switch (widget.level) {
      case 1: return 3;
      case 2: return 1;
      default: return 0;
    }
  }

  /// Qué FRACCIÓN del verso se oculta en cada ronda. El nivel 1 arranca
  /// con apenas 25% oculto (solo "unas partes" — el resto totalmente
  /// visible) y va creciendo. El nivel 3 oculta todo.
  double _hiddenRatioForRound(int round) {
    if (widget.level == 3) return 1.0;
    if (widget.level == 1) {
      // N1: 25% → 50% → 75% (3 rondas)
      const ratios = [0.25, 0.50, 0.75];
      return ratios[round.clamp(0, ratios.length - 1)];
    }
    // N2: 55% → 80% (2 rondas)
    const ratios = [0.55, 0.80];
    return ratios[round.clamp(0, ratios.length - 1)];
  }

  /// Sigma del blur aplicado a las palabras OCULTAS. El nivel sube la
  /// intensidad para que palabras "oscuras" del nivel 3 sean realmente
  /// ilegibles, mientras las del nivel 1 dejan adivinar la forma.
  double get _blurSigma {
    if (_peeking || _showingClear || widget.finished) return 0.0;
    switch (widget.level) {
      case 1: return 5.0;
      case 2: return 9.0;
      default: return 18.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _allWords = _studyWords(widget.targetText);
    _round = 0;
    _peeksLeft = _peeksAtStart();
    _recomputeHiddenForRound();
    _initSpeech();
    _startInitialClearView();
  }

  /// Recompute qué palabras se ocultan en la ronda actual. Para nivel 1
  /// hace chunks contiguos (más parecido a "ocultar una sección"); para
  /// nivel 2 mezcla varios chunks; para nivel 3 oculta todo.
  void _recomputeHiddenForRound() {
    final total = _allWords.length;
    if (total == 0) {
      _hiddenIndexes = <int>{};
      return;
    }
    if (widget.level == 3) {
      _hiddenIndexes = Set<int>.from(List<int>.generate(total, (i) => i));
      return;
    }
    final ratio = _hiddenRatioForRound(_round);
    final targetCount = (total * ratio).round().clamp(1, total);
    final rng = math.Random(widget.targetText.hashCode ^ _round * 31);
    final hidden = <int>{};
    // Para N1 round 0 con pocas palabras → un solo chunk contiguo. Para
    // rondas más avanzadas o N2 → varios chunks pequeños distribuidos.
    final chunkCount = widget.level == 1 && _round == 0
        ? 1
        : (widget.level == 1 ? 2 + _round : 2 + _round);
    final perChunk = math.max(1, (targetCount / chunkCount).round());
    final segment = math.max(perChunk + 1, total ~/ chunkCount);
    for (var i = 0; i < chunkCount; i++) {
      final segStart = i * segment;
      final segEnd = math.min(total, segStart + segment);
      if (segEnd <= segStart) continue;
      final room = segEnd - segStart - perChunk;
      final chunkStart = segStart + (room <= 0 ? 0 : rng.nextInt(room + 1));
      for (var j = 0; j < perChunk && chunkStart + j < total; j++) {
        hidden.add(chunkStart + j);
      }
    }
    // Si por redondeo quedó corto, agregar palabras random hasta llegar.
    while (hidden.length < targetCount) {
      hidden.add(rng.nextInt(total));
    }
    _hiddenIndexes = hidden;
  }

  void _startInitialClearView() {
    final secs = _previewSeconds(_round);
    if (secs <= 0) {
      _showingClear = false;
      return;
    }
    _showingClear = true;
    _clearViewTimer?.cancel();
    _clearViewTimer = Timer(Duration(seconds: secs), () {
      if (!mounted) return;
      setState(() => _showingClear = false);
    });
  }

  @override
  void didUpdateWidget(_FogStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText ||
        oldWidget.level != widget.level) {
      _allWords = _studyWords(widget.targetText);
      _recognized = '';
      _accumulated = '';
      _ratio = 0;
      _round = 0;
      _peeksLeft = _peeksAtStart();
      _recomputeHiddenForRound();
      _startInitialClearView();
    }
  }

  Future<bool> _initSpeech() async {
    await _speech?.cancel();
    final speech = stt.SpeechToText();
    _speech = speech;
    final ok = await speech.initialize(
      debugLogging: true,
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          if (!_userStopRequested && _listening) {
            if (_restartPending) return;
            _restartPending = true;
            Future.delayed(const Duration(milliseconds: 250), () {
              _restartPending = false;
              if (!mounted || _userStopRequested) return;
              _autoRestartListen();
            });
            return;
          }
          _pulse.stop();
          _pulse.value = 0;
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        debugPrint(
            'STT fog error: ${error.errorMsg} permanent=${error.permanent}');
        final recoverable = error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'error_no_speech';
        if (recoverable && !_userStopRequested && _listening) {
          if (_restartPending) return;
          _restartPending = true;
          Future.delayed(const Duration(milliseconds: 250), () {
            _restartPending = false;
            if (!mounted || _userStopRequested) return;
            _autoRestartListen();
          });
          return;
        }
        _pulse.stop();
        _pulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
        });
      },
    );
    if (!mounted) return false;
    setState(() => _ready = ok);
    return ok;
  }

  Future<String> _resolveSpanishLocale() async {
    try {
      final s = _speech;
      if (s == null) return 'es_ES';
      final locales = await s.locales();
      for (final wanted in [
        'es_ES', 'es-ES', 'es_MX', 'es-MX', 'es_US', 'es-US', 'es_419', 'es-419',
      ]) {
        final m = locales.firstWhere(
          (l) => l.localeId.replaceAll('-', '_') == wanted.replaceAll('-', '_'),
          orElse: () => stt.LocaleName('', ''),
        );
        if (m.localeId.isNotEmpty) return m.localeId;
      }
      final anyEs = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('es'),
        orElse: () => stt.LocaleName('', ''),
      );
      if (anyEs.localeId.isNotEmpty) return anyEs.localeId;
    } catch (_) {}
    return 'es_ES';
  }

  Future<void> _autoRestartListen() async {
    if (!mounted || !_listening || _userStopRequested) return;
    final s = _speech;
    if (s == null) return;
    // Preserva lo reconocido en la sesión que se cerró por pausa, para
    // concatenarlo al reabrir — sino el progreso se reinicia en cada pausa.
    if (_recognized.trim().isNotEmpty) {
      _accumulated = _accumulated.isEmpty
          ? _recognized.trim()
          : '${_accumulated.trim()} ${_recognized.trim()}';
      _recognized = '';
    }
    try {
      final locale = await _resolveSpanishLocale();
      await s.listen(
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 30),
        onResult: _onResult,
      );
    } catch (e) {
      debugPrint('STT fog auto-restart error: $e');
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech?.cancel();
    _peekTimer?.cancel();
    _clearViewTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_starting || widget.finished) return;
    final speech = _speech;
    if (_listening || (speech?.isListening ?? false)) {
      _userStopRequested = true;
      _pulse.stop();
      _pulse.value = 0;
      HapticFeedback.selectionClick();
      await speech?.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _starting = true;
    _userStopRequested = false;
    try {
      if (_speech == null || !_ready) {
        final ok = await _initSpeech();
        if (!mounted || !ok) return;
      }
      HapticFeedback.lightImpact();
      _recognized = '';
      _accumulated = '';
      _ratio = 0;
      _pulse.repeat();
      setState(() => _listening = true);
      final locale = await _resolveSpanishLocale();
      await _speech!.listen(
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 30),
        onResult: _onResult,
      );
    } catch (_) {
      if (mounted) {
        _pulse.stop();
        _pulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
        });
      }
    } finally {
      _starting = false;
    }
  }

  void _peek() {
    if (_peeksLeft <= 0 || _peeking || _showingClear) return;
    HapticFeedback.lightImpact();
    setState(() {
      _peeking = true;
      _peeksLeft--;
    });
    _peekTimer?.cancel();
    _peekTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _peeking = false);
    });
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    // Texto reconocido en esta sesión + lo acumulado de sesiones previas.
    // Calificamos con similitud difusa contra TODO el verso (igual que el
    // ejercicio de leer en voz alta) — robusto a palabras mal reconocidas
    // y a los reinicios del STT de Android entre pausas.
    _recognized = result.recognizedWords;
    final fullText = _accumulated.isEmpty
        ? _recognized
        : '${_accumulated.trim()} ${_recognized.trim()}';
    final ratio = _speechSimilarity(fullText, widget.targetText);
    if (ratio != _ratio) {
      setState(() => _ratio = ratio);
    }
    // Al alcanzar el 60% en esta ronda → si quedan rondas avanza (con preview
    // breve y mic apagado); si es la última, notifica completed al parent.
    if (ratio >= _passRatio) {
      _userStopRequested = true;
      _speech?.stop();
      _pulse.stop();
      _pulse.value = 0;
      HapticFeedback.mediumImpact();
      if (_round + 1 < _maxRounds) {
        setState(() {
          _round++;
          _recognized = '';
          _accumulated = '';
          _ratio = 0;
          _listening = false;
          _peeksLeft = _peeksAtStart();
          _recomputeHiddenForRound();
        });
        _startInitialClearView();
      } else {
        setState(() => _listening = false);
        widget.onCompleted();
      }
    }
  }

  String get _levelLabel {
    final maxR = _maxRounds;
    final base = switch (widget.level) {
      1 => 'Niebla N1',
      2 => 'Niebla N2',
      _ => 'Niebla N3',
    };
    return maxR > 1
        ? '$base · ronda ${_round + 1}/$maxR'
        : base;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio;
    final percent = (ratio * 100).round();
    final targetPercent = (_passRatio * 100).round();
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
                    : _levelLabel,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              Text(
                _showingClear
                    ? 'Memorizando…'
                    : '$percent% · meta $targetPercent%',
                style: TextStyle(
                  color: _showingClear
                      ? RefColors.sun
                      : (ratio >= _passRatio
                          ? RefColors.lime
                          : RefColors.muted),
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
          // Render por palabra — solo las que están en `_hiddenIndexes`
          // reciben el blur. El resto queda totalmente legible. Es lo que
          // hace que "nivel 1" sea visualmente "solo unas partes ocultas"
          // en vez de "toda la pantalla borrosa".
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var i = 0; i < _allWords.length; i++)
                (() {
                  final isHidden = !_peeking &&
                      !_showingClear &&
                      !widget.finished &&
                      _hiddenIndexes.contains(i);
                  const baseStyle = TextStyle(
                    fontSize: 22,
                    height: 1.36,
                    fontWeight: FontWeight.w900,
                    color: RefColors.ink,
                  );
                  if (!isHidden) {
                    return Text(_allWords[i], style: baseStyle);
                  }
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _blurSigma,
                      sigmaY: _blurSigma,
                    ),
                    child: Text(_allWords[i], style: baseStyle),
                  );
                })(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Botón "Ver" — muestra el texto limpio por 2.5s. Los usos están
        // limitados según el nivel (N1=3, N2=1, N3=0). En el preview
        // cronometrado el botón queda oculto (no tiene sentido).
        if (!widget.finished && !_showingClear && _peeksAtStart() > 0)
          GestureDetector(
            onTap: _peeksLeft > 0 ? _peek : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _peeking
                    ? RefColors.lime.withValues(alpha: .18)
                    : RefColors.glassSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _peeking
                      ? RefColors.lime.withValues(alpha: .55)
                      : RefColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _peeking
                        ? Icons.visibility_rounded
                        : Icons.visibility_outlined,
                    color: _peeksLeft > 0
                        ? (_peeking ? RefColors.lime : RefColors.muted)
                        : RefColors.dim,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _peeking
                        ? 'Visible…'
                        : 'Ver · $_peeksLeft restantes',
                    style: TextStyle(
                      color: _peeksLeft > 0
                          ? (_peeking ? RefColors.lime : RefColors.ink)
                          : RefColors.dim,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (widget.finished)
          Glass(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            color: RefColors.lime.withValues(alpha: .14),
            border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: RefColors.lime, size: 36),
                const SizedBox(height: 10),
                const Text(
                  '¡Recitado!',
                  style: TextStyle(
                    color: RefColors.lime,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recitaste al menos el ${(_passRatio * 100).round()}% del texto.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: RefColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
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
                      _listening ? 'Escuchando...' : 'Recita el texto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
