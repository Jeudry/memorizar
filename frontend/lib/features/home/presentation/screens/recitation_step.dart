// Generado del refactor de ui_screens.dart.
// _RecitationStep (recitación final + voz guiada).
part of '../ui_screens.dart';

class _RecitationStep extends StatefulWidget {
  final String targetText;
  final bool finalMode;
  /// Nivel de dificultad de la recitación:
  /// 1 = un único trozo seguido oculto (~25% del verso) — "completar recitación".
  /// 2 = varios trozos contiguos (2-3 grupos de palabras adyacentes, ~35% total).
  /// 3 = todo el texto oculto (memoria pura). `finalMode=true` lo fuerza.
  final int level;
  final _ListeningColorMode colorMode;
  final void Function(bool passed) onCompleted;

  const _RecitationStep({
    required this.targetText,
    required this.finalMode,
    required this.colorMode,
    required this.onCompleted,
    this.level = 2,
  });

  @override
  State<_RecitationStep> createState() => _RecitationStepState();
}

class _RecitationStepState extends State<_RecitationStep>
    with SingleTickerProviderStateMixin {
  stt.SpeechToText? _speech;
  late final AnimationController _micPulse;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  bool _startingListening = false;
  bool _warmingMic = false;
  String _lastSpokenWord = '';
  int _attemptsLeft = 7;
  int? _lastWrongAt;
  int _processedTokenCount = 0;
  String _lastRawText = '';

  late List<String> _allWords;
  late Set<int> _hiddenIndexes; // word indexes that need to be recited
  late List<int> _orderedHidden; // hidden indexes sorted (text order)
  late Set<int> _solvedIndexes;
  late Set<int> _skippedIndexes;
  int _activePointer = 0; // index into _orderedHidden

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _resetExerciseState();
    // Pre-warm STT en background para evitar cold-start en el primer tap.
    _initSpeech();
  }

  @override
  void didUpdateWidget(_RecitationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText ||
        oldWidget.finalMode != widget.finalMode ||
        oldWidget.level != widget.level) {
      _micPulse.stop();
      _micPulse.value = 0;
      _speech?.cancel();
      setState(_resetExerciseState);
    }
  }

  void _resetExerciseState() {
    _allWords = _studyWords(widget.targetText);
    _hiddenIndexes = _pickHiddenIndexes();
    _orderedHidden = _hiddenIndexes.toList()..sort();
    _solvedIndexes = <int>{};
    _skippedIndexes = <int>{};
    _activePointer = 0;
    _attemptsLeft = 7;
    _lastSpokenWord = '';
    _lastWrongAt = null;
    _processedTokenCount = 0;
    _completed = false;
    _listening = false;
    _startingListening = false;
  }

  /// Selecciona qué palabras se ocultan según el nivel. La idea es que en
  /// niveles bajos las palabras ocultas estén AGRUPADAS (trozos contiguos)
  /// para que el usuario recite frases naturales en lugar de saltar de
  /// palabra suelta a palabra suelta — eso es lo que se sentía raro.
  Set<int> _pickHiddenIndexes() {
    final total = _allWords.length;
    if (total == 0) return <int>{};
    if (widget.finalMode || widget.level == 3) {
      return Set<int>.from(List<int>.generate(total, (i) => i));
    }
    final rng = math.Random();
    if (widget.level == 1) {
      // UN solo trozo contiguo de ~25% del verso. Empieza en una posición
      // aleatoria pero respeta los bordes (no arranca al final).
      final chunkSize = (total * 0.25).round().clamp(2, total - 1);
      final maxStart = total - chunkSize;
      final start = maxStart <= 0 ? 0 : rng.nextInt(maxStart + 1);
      return Set<int>.from(List<int>.generate(chunkSize, (i) => start + i));
    }
    // Nivel 2: 2-3 chunks de palabras adyacentes, ~35% en total. Cada
    // chunk se ubica en un segmento distinto del verso para que los
    // huecos cubran principio, medio y final.
    final targetHidden = (total * 0.35).round().clamp(4, total - 2);
    final chunkCount = total < 12 ? 2 : 3;
    final perChunk = math.max(2, (targetHidden / chunkCount).round());
    final hidden = <int>{};
    final segment = math.max(perChunk + 1, total ~/ chunkCount);
    for (var i = 0; i < chunkCount; i++) {
      final segStart = i * segment;
      final segEnd = math.min(total, segStart + segment);
      final room = segEnd - segStart - perChunk;
      final chunkStart = segStart + (room <= 0 ? 0 : rng.nextInt(room + 1));
      for (var j = 0; j < perChunk && chunkStart + j < total; j++) {
        hidden.add(chunkStart + j);
      }
    }
    return hidden;
  }

  /// `true` cuando el usuario tocó el mic para detener. Se distingue de la
  /// señal `done` que dispara Android al detectar pausa breve — en ese caso
  /// reabrimos la sesión automáticamente para no interrumpir al usuario.
  bool _userStopRequested = false;
  bool _restartPending = false;

  Future<bool> _initSpeech() async {
    await _speech?.cancel();
    final speech = stt.SpeechToText();
    _speech = speech;
    final available = await speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          // Si el usuario NO tocó stop pero Android cortó la sesión por
          // pausa, reabrimos automáticamente para que pueda seguir.
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
          _micPulse.stop();
          _micPulse.value = 0;
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        debugPrint(
          'STT recitation error: ${error.errorMsg} permanent=${error.permanent}',
        );
        // Pausas breves → Android cierra con error_speech_timeout pero no
        // es fatal; reabrimos automáticamente para que el usuario pueda
        // seguir recitando.
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
        _micPulse.stop();
        _micPulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
        });
      },
    );
    if (!mounted) return false;
    setState(() => _ready = available);
    return available;
  }

  /// Devuelve el locale español disponible en el dispositivo (es_ES, es_MX,
  /// es_US, es_419 — el que exista) o `es_ES` como último recurso.
  Future<String> _resolveSpanishLocale() async {
    try {
      final s = _speech;
      if (s == null) return 'es_ES';
      final locales = await s.locales();
      for (final wanted in [
        'es_ES', 'es-ES',
        'es_MX', 'es-MX',
        'es_US', 'es-US',
        'es_419', 'es-419',
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
    } catch (e) {
      debugPrint('STT recitation locales lookup failed: $e');
    }
    return 'es_ES';
  }

  /// Reabre `_speech.listen()` sin resetear el estado del ejercicio.
  /// Usado cuando Android cierra por pausa pero el usuario quiere seguir.
  Future<void> _autoRestartListen() async {
    if (!mounted || !_listening || _userStopRequested) return;
    final speech = _speech;
    if (speech == null) return;
    try {
      final localeId = await _resolveSpanishLocale();
      debugPrint('STT recitation auto-restart with locale=$localeId');
      await speech.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 30),
        onResult: _handleRecognition,
      );
    } catch (e) {
      debugPrint('STT recitation auto-restart error: $e');
    }
  }

  @override
  void dispose() {
    _micPulse.dispose();
    _speech?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_startingListening || _completed) return;
    final speech = _speech;
    if (_listening || (speech?.isListening ?? false)) {
      _userStopRequested = true; // bandera para no reabrir auto
      _micPulse.stop();
      _micPulse.value = 0;
      HapticFeedback.selectionClick();
      await speech?.stop();
      if (mounted) {
        setState(() {
          _listening = false;
          _warmingMic = false;
        });
      }
      return;
    }
    _startingListening = true;
    _userStopRequested = false;
    setState(() {
      _processedTokenCount = 0;
      _lastRawText = '';
    });
    try {
      if (_speech == null || !_ready) {
        final available = await _initSpeech();
        if (!mounted || !available) return;
      }
      HapticFeedback.lightImpact();
      _micPulse.repeat();
      setState(() {
        _listening = true;
        _warmingMic = true;
      });
      final localeId = await _resolveSpanishLocale();
      debugPrint('STT recitation listen with locale=$localeId');
      _speech!
          .listen(
            localeId: localeId,
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              partialResults: true,
              cancelOnError: false,
            ),
            listenFor: const Duration(seconds: 90),
            pauseFor: const Duration(seconds: 30),
            onResult: _handleRecognition,
          )
          .catchError((Object e) {
        debugPrint('STT recitation listen catchError: $e');
        if (!mounted) return;
        _micPulse.stop();
        _micPulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
          _warmingMic = false;
        });
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _warmingMic = false);
    } catch (_) {
      if (!mounted) return;
      _micPulse.stop();
      _micPulse.value = 0;
      setState(() {
        _ready = false;
        _listening = false;
        _warmingMic = false;
      });
    } finally {
      _startingListening = false;
    }
  }

  String _normalizeToken(String token) =>
      token.toLowerCase().replaceAll(RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]'), '');

  void _handleRecognition(SpeechRecognitionResult result) {
    if (!mounted) return;
    final text = result.recognizedWords;
    final isFinal = result.finalResult;
    final rawTokens = text
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    if (rawTokens.isEmpty) return;
    // If iOS reset the running text (new sentence), restart processing pointer.
    if (text.length < _lastRawText.length || _processedTokenCount > rawTokens.length) {
      _processedTokenCount = 0;
    }
    _lastRawText = text;
    if (rawTokens.last != _lastSpokenWord) {
      setState(() => _lastSpokenWord = rawTokens.last);
    }
    final lockedCount = isFinal ? rawTokens.length : rawTokens.length - 1;
    var processedNow = _processedTokenCount;
    void processToken(String rawToken, {required bool locked}) {
      if (_completed) return;
      if (_activePointer >= _orderedHidden.length) return;
      final expectedIdx = _orderedHidden[_activePointer];
      final expected = _allWords[expectedIdx];
      // Match in expected order first (fast path).
      if (_voiceMatch(rawToken, expected)) {
        HapticFeedback.lightImpact();
        setState(() {
          _solvedIndexes.add(expectedIdx);
          // Advance pointer past any already-solved indexes.
          while (_activePointer < _orderedHidden.length &&
              _solvedIndexes.contains(_orderedHidden[_activePointer])) {
            _activePointer += 1;
          }
        });
        if (_activePointer >= _orderedHidden.length && !_completed) {
          _completed = true;
          _micPulse.stop();
          _micPulse.value = 0;
          HapticFeedback.heavyImpact();
          _speech?.cancel();
          if (mounted) setState(() => _listening = false);
          widget.onCompleted(_skippedIndexes.isEmpty);
        }
        return;
      }
      // Out-of-order match: user recited the full content, fill any remaining
      // hidden slot whose word matches.
      for (final idx in _orderedHidden) {
        if (_solvedIndexes.contains(idx)) continue;
        if (_voiceMatch(rawToken, _allWords[idx])) {
          HapticFeedback.lightImpact();
          setState(() {
            _solvedIndexes.add(idx);
            while (_activePointer < _orderedHidden.length &&
                _solvedIndexes.contains(_orderedHidden[_activePointer])) {
              _activePointer += 1;
            }
          });
          if (_activePointer >= _orderedHidden.length && !_completed) {
            _completed = true;
            _micPulse.stop();
            _micPulse.value = 0;
            HapticFeedback.heavyImpact();
            _speech?.cancel();
            if (mounted) setState(() => _listening = false);
            widget.onCompleted(_skippedIndexes.isEmpty);
          }
          return;
        }
      }
      // Tokens that are part of the visible (non-hidden) content shouldn't
      // be penalized — the user is reciting the verse around the gaps.
      for (var i = 0; i < _allWords.length; i++) {
        if (_hiddenIndexes.contains(i)) continue;
        if (_voiceMatch(rawToken, _allWords[i])) return;
      }
      if (locked) {
        HapticFeedback.mediumImpact();
        setState(() {
          _lastWrongAt = DateTime.now().millisecondsSinceEpoch;
          if (_attemptsLeft > 0) _attemptsLeft -= 1;
        });
        if (_attemptsLeft == 0 && !_completed) {
          _completed = true;
          _micPulse.stop();
          _micPulse.value = 0;
          HapticFeedback.heavyImpact();
          _speech?.cancel();
          if (mounted) setState(() => _listening = false);
          widget.onCompleted(false);
        }
      }
    }

    for (var i = processedNow; i < lockedCount; i++) {
      processToken(rawTokens[i], locked: true);
      processedNow = i + 1;
    }
    if (!isFinal && processedNow < rawTokens.length) {
      final lastIdx = rawTokens.length - 1;
      final beforeAdvance = _activePointer;
      processToken(rawTokens[lastIdx], locked: false);
      if (_activePointer != beforeAdvance) {
        processedNow = lastIdx + 1;
      }
    }
    _processedTokenCount = processedNow;
  }

  @override
  Widget build(BuildContext context) {
    final isBlue = widget.colorMode == _ListeningColorMode.blue;
    final accent = _completed
        ? RefColors.lime
        : isBlue
        ? RefColors.cyan
        : RefColors.pink;
    final wrongRecent =
        _lastWrongAt != null &&
        DateTime.now().millisecondsSinceEpoch - _lastWrongAt! < 1200;
    final activeIdx = _activePointer < _orderedHidden.length
        ? _orderedHidden[_activePointer]
        : -1;
    final solvedCount = _solvedIndexes.length;
    final totalCount = _orderedHidden.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_completed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(
                scale: 0.85 + 0.15 * t,
                child: Opacity(opacity: t, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: RefColors.success,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: RefColors.lime.withValues(alpha: .55),
                      blurRadius: 26,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: RefColors.successInk,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Recitación completada!',
                        style: TextStyle(
                          color: RefColors.successInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Palabra ${(_activePointer + 1).clamp(1, totalCount == 0 ? 1 : totalCount)} de ${totalCount == 0 ? 1 : totalCount}',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              Text(
                '$solvedCount/$totalCount completadas',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Glass(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            gradient: LinearGradient(
              colors: [
                RefColors.violet.withValues(alpha: .30),
                RefColors.sun.withValues(alpha: .28),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < _allWords.length; i++)
                          if (_hiddenIndexes.contains(i))
                            _HiddenWord(
                              wordLength: _allWords[i].length,
                              active: i == activeIdx,
                              pink: !isBlue,
                              solved: _solvedIndexes.contains(i),
                              skipped: _skippedIndexes.contains(i),
                              wrongFlash: i == activeIdx && wrongRecent,
                              word: _allWords[i],
                            )
                          else
                            _LetterWord(_allWords[i]),
                        const Text(
                          '.',
                          style: TextStyle(
                            color: RefColors.muted,
                            fontSize: 22,
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
        ),
        const SizedBox(height: 14),
        Glass(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                          animation: _micPulse,
                          builder: (context, _) {
                            final t = _micPulse.value;
                            return Container(
                              width: 56 + 14 * t,
                              height: 56 + 14 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withValues(alpha: 1 - t),
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
                          color: accent.withValues(
                            alpha: _listening ? .55 : .18,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: .85),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .35),
                              blurRadius: _listening ? 28 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _startingListening
                              ? Icons.more_horiz_rounded
                              : _listening
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: wrongRecent
                        ? RefColors.urgent.withValues(alpha: .18)
                        : HtmlRefColors.glassSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wrongRecent
                          ? RefColors.urgent
                          : HtmlRefColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    _lastSpokenWord.isEmpty
                        ? (_warmingMic
                            ? 'Preparando mic…'
                            : _listening
                                ? 'Escuchando…'
                                : 'Toca el mic y recita')
                        : _lastSpokenWord,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _lastSpokenWord.isEmpty
                          ? RefColors.dim
                          : RefColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: .6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'intentos',
                      style: TextStyle(
                        color: accent.withValues(alpha: .9),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    Text(
                      'restantes',
                      style: TextStyle(
                        color: accent.withValues(alpha: .9),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_attemptsLeft',
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
