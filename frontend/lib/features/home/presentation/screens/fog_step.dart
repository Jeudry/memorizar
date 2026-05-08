// Generado del refactor de ui_screens.dart.
// _FogStep (recitación con neblina progresiva).
part of '../ui_screens.dart';

class _FogStep extends StatefulWidget {
  final String targetText;
  final int round; // 0,1,2
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
  stt.SpeechToText? _speech;
  bool _ready = false;
  bool _listening = false;
  bool _starting = false;
  late AnimationController _pulse;
  late List<String> _allWords;
  Set<int> _solved = <int>{};
  int _processedTokenCount = 0;
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _allWords = _studyWords(widget.targetText);
    _initSpeech();
  }

  @override
  void didUpdateWidget(_FogStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText) {
      _allWords = _studyWords(widget.targetText);
      _solved = <int>{};
      _processedTokenCount = 0;
    }
    if (oldWidget.round != widget.round) {
      _solved = <int>{};
      _processedTokenCount = 0;
      _lastSpoken = '';
    }
  }

  Future<bool> _initSpeech() async {
    await _speech?.cancel();
    final speech = stt.SpeechToText();
    _speech = speech;
    final ok = await speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          _pulse.stop();
          _pulse.value = 0;
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
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

  @override
  void dispose() {
    _pulse.dispose();
    _speech?.cancel();
    super.dispose();
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]'), '');

  Future<void> _toggle() async {
    if (_starting || widget.finished) return;
    final speech = _speech;
    if (_listening || (speech?.isListening ?? false)) {
      _pulse.stop();
      _pulse.value = 0;
      HapticFeedback.selectionClick();
      await speech?.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _starting = true;
    try {
      if (_speech == null || !_ready) {
        final ok = await _initSpeech();
        if (!mounted || !ok) return;
      }
      HapticFeedback.lightImpact();
      _processedTokenCount = 0;
      _solved = <int>{};
      _pulse.repeat();
      setState(() => _listening = true);
      await _speech!.listen(
        localeId: 'es_ES',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 8),
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

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final text = result.recognizedWords;
    final isFinal = result.finalResult;
    final raw = text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    if (raw.isEmpty) return;
    if (raw.last != _lastSpoken) {
      setState(() => _lastSpoken = raw.last);
    }
    final lockedCount = isFinal ? raw.length : raw.length - 1;
    var processedNow = _processedTokenCount;
    int pointer = _solved.length;
    void process(String token) {
      if (pointer >= _allWords.length) return;
      if (token.trim().isEmpty) return;
      if (_voiceMatch(token, _allWords[pointer])) {
        setState(() => _solved.add(pointer));
        pointer += 1;
        HapticFeedback.lightImpact();
      }
    }
    for (var i = processedNow; i < lockedCount; i++) {
      process(raw[i]);
      processedNow = i + 1;
    }
    _processedTokenCount = processedNow;
    if (_solved.length >= _allWords.length) {
      _speech?.stop();
      _pulse.stop();
      _pulse.value = 0;
      setState(() => _listening = false);
      widget.onRoundCompleted();
    }
  }

  double get _blurSigma {
    if (widget.finished) return 18.0;
    switch (widget.round) {
      case 0:
        return 3.0;
      case 1:
        return 7.0;
      default:
        return 14.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final solvedCount = _solved.length;
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
              Text(
                '$solvedCount / $total',
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter:
                  ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
              child: Text(
                widget.targetText,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.finished)
          Glass(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            color: RefColors.lime.withValues(alpha: .14),
            border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
            child: Column(
              children: const [
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
                  'Recitaste el texto de memoria.',
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

