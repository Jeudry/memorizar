// Generado del refactor de ui_screens.dart.
// _RecitationStep (recitación final + voz guiada).
part of '../ui_screens.dart';

class _RecitationStep extends StatefulWidget {
  final String targetText;
  final bool finalMode;
  final _ListeningColorMode colorMode;
  final void Function(bool passed) onCompleted;

  const _RecitationStep({
    required this.targetText,
    required this.finalMode,
    required this.colorMode,
    required this.onCompleted,
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
        oldWidget.finalMode != widget.finalMode) {
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

  Set<int> _pickHiddenIndexes() {
    if (widget.finalMode) {
      return Set<int>.from(List<int>.generate(_allWords.length, (i) => i));
    }
    final rng = math.Random();
    final ratio = 0.35;
    final count = (_allWords.length * ratio).round().clamp(
      1,
      _allWords.length - 1,
    );
    final indices = List<int>.generate(_allWords.length, (i) => i);
    indices.shuffle(rng);
    return indices.take(count).toSet();
  }

  Future<bool> _initSpeech() async {
    await _speech?.cancel();
    final speech = stt.SpeechToText();
    _speech = speech;
    final available = await speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          _micPulse.stop();
          _micPulse.value = 0;
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
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
      // Visual "warming up": user sees 'Preparando mic...' for 450ms while the
      // iOS audio session activates. Without this the first word always gets
      // swallowed because capture starts a few hundred ms after listen().
      setState(() {
        _listening = true;
        _warmingMic = true;
      });
      // Fire listen() — do NOT await its full completion (it returns when the
      // session ends). Errors are caught and reset state.
      _speech!
          .listen(
            localeId: 'es_ES',
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              partialResults: true,
              cancelOnError: false,
            ),
            listenFor: const Duration(seconds: 90),
            pauseFor: const Duration(seconds: 12),
            onResult: _handleRecognition,
          )
          .catchError((Object _) {
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
