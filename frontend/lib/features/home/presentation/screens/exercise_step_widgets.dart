// AUTO-GENERATED extraction from ui_screens.dart (refactor PR-D).
// Tightly-coupled exercise-flow widgets — kept in this library to
// preserve cross-class private visibility.
part of '../ui_screens.dart';

class _VerseBlock extends StatelessWidget {
  final String text;
  final bool correct;
  final bool selected;
  final bool wrong;

  const _VerseBlock(
    this.text, {
    this.correct = false,
    this.selected = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : wrong
        ? RefColors.urgent
        : selected
        ? RefColors.pink
        : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: correct
            ? RefColors.lime.withValues(alpha: .12)
            : wrong
            ? RefColors.urgent.withValues(alpha: .12)
            : selected
            ? Colors.transparent
            : RefColors.glassSoft,
        gradient: selected
            ? LinearGradient(
                colors: [
                  RefColors.pink.withValues(alpha: .2),
                  const Color(0xFF7C3AFF).withValues(alpha: .1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? RefColors.pink : accent.withValues(alpha: .48),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          if (correct || wrong)
            Icon(
              correct ? Icons.check_rounded : Icons.close_rounded,
              color: correct ? RefColors.lime : RefColors.urgent,
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _LostPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _LostPanel({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      color: RefColors.urgent.withValues(alpha: .12),
      border: Border.all(color: RefColors.urgent.withValues(alpha: .55)),
      child: Column(
        children: [
          const Icon(
            Icons.timer_off_rounded,
            color: RefColors.urgent,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.urgent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onRetry();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [RefColors.pink, RefColors.urgent],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Reintentar',
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
        ],
      ),
    );
  }
}

class _InlineFlashStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InlineFlashStat(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${label.toUpperCase()}: ',
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? RefColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CompleteStatsCard extends StatelessWidget {
  final bool level2;
  final bool showFirst;
  final String firstValue;
  final String firstLabel;
  final String secondValue;
  final String secondLabel;
  final String timeValue;
  final VoidCallback? onPistaTap;

  const _CompleteStatsCard({
    this.level2 = false,
    this.showFirst = true,
    this.firstValue = '1/3',
    this.firstLabel = 'HUECOS',
    this.secondValue = '2/2',
    this.secondLabel = 'INTENTOS',
    this.timeValue = '00:45',
    this.onPistaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      gradient: LinearGradient(
        colors: const [Color(0x55372B86), Color(0x668B5B21)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (showFirst) _InlineFlashStat(firstLabel, firstValue),
          _InlineFlashStat(secondLabel, secondValue),
          if (level2)
            _InlineFlashStat('TIEMPO', timeValue, valueColor: RefColors.sun),
          if (onPistaTap != null)
            GestureDetector(
              onTap: onPistaTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: RefColors.cyan.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RefColors.cyan.withValues(alpha: .3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 13,
                      color: RefColors.cyan,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PISTA',
                      style: TextStyle(
                        color: RefColors.cyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header compacto de ejercicio: referencia del versículo a la izquierda, e
/// intentos + pista a la derecha (en vez de un cuadro grande de estadísticas).
class _ExerciseHeaderRow extends StatelessWidget {
  final String title;
  final int attemptsLeft;
  final VoidCallback? onPistaTap;

  const _ExerciseHeaderRow({
    required this.title,
    required this.attemptsLeft,
    this.onPistaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$attemptsLeft/3',
          style: TextStyle(
            color: attemptsLeft <= 1 ? RefColors.urgent : RefColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'intentos',
          style: TextStyle(
            color: RefColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (onPistaTap != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onPistaTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RefColors.cyan.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RefColors.cyan.withValues(alpha: .3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 13, color: RefColors.cyan),
                  SizedBox(width: 4),
                  Text(
                    'Pista',
                    style: TextStyle(
                      color: RefColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final String label;
  final bool active;

  const _WordChip(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    final accent = active ? RefColors.cyan : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: .14)
            : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _FirstLetterSentence extends StatelessWidget {
  final String? text;
  final int level;
  final List<String>? targets;
  final List<int>? targetPositions;
  final List<String?>? answers;
  final int activeIndex;
  final ValueChanged<int>? onBlankTap;

  const _FirstLetterSentence({
    this.text,
    required this.level,
    this.targets,
    this.targetPositions,
    this.answers,
    this.activeIndex = 0,
    this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHarder = level >= 2;
    final sourceText = text ?? _cardStudyText(context);
    final words = _studyWords(sourceText);
    final targetsData = targetPositions != null && targets != null
        ? (targets!, targetPositions!)
        : _firstLetterTargetsWithPositions(sourceText, level: level);
    final targetWords = targetsData.$1;
    final positions = targetsData.$2;
    final answerWords =
        answers ?? List<String?>.filled(targetWords.length, null);
    final visibleWords = switch (level) {
      1 => 3,
      2 => 1,
      _ => 0,
    };
    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .30),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Wrap(
            spacing: isHarder ? 8 : 10,
            runSpacing: isHarder ? 12 : 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              for (var wordIndex = 0; wordIndex < words.length; wordIndex++)
                if (wordIndex < visibleWords)
                  _LetterWord(words[wordIndex])
                else
                  _letterWidget(
                    wordIndex,
                    words[wordIndex],
                    positions,
                    answerWords,
                  ),
              const Text(
                '.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letterWidget(
    int wordIndex,
    String word,
    List<int> targetPositions,
    List<String?> answerWords,
  ) {
    final targetIndex = targetPositions.indexOf(wordIndex);
    if (targetIndex == -1) return _LetterWord(word);
    return _LetterBlank(
      answer: answerWords[targetIndex],
      active: activeIndex == targetIndex && answerWords[targetIndex] == null,
      wordLength: word.length,
      onTap: () => onBlankTap?.call(targetIndex),
    );
  }
}

class _LetterWord extends StatelessWidget {
  final String text;

  const _LetterWord(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -.2,
      ),
    );
  }
}

class _LetterBlank extends StatefulWidget {
  final String? answer;
  final bool active;
  final int wordLength;
  final VoidCallback onTap;

  const _LetterBlank({
    required this.answer,
    required this.active,
    required this.wordLength,
    required this.onTap,
  });

  @override
  State<_LetterBlank> createState() => _LetterBlankState();
}

class _LetterBlankState extends State<_LetterBlank> {
  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _ensureVisible();
    }
  }

  @override
  void didUpdateWidget(_LetterBlank oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _ensureVisible();
    }
  }

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = widget.answer != null;
    final accent = complete
        ? RefColors.lime
        : widget.active
        ? RefColors.cyan
        : RefColors.border;
    final displayLength = complete ? widget.wordLength.clamp(1, 14) : 6;
    return GestureDetector(
      onTap: complete ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minWidth: (displayLength * 10.0).clamp(28, 160)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: widget.active
              ? accent.withValues(alpha: .35)
              : accent.withValues(alpha: complete ? .16 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: widget.active ? 1.0 : .5),
            width: widget.active ? 2.4 : 1.5,
          ),
          boxShadow: widget.active
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .6),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.answer ?? '______',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: complete ? RefColors.lime : RefColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _KeyboardCard extends StatelessWidget {
  final ValueChanged<String>? onLetterTap;

  const _KeyboardCard({this.onLetterTap});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ñ'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
    ];
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                if (i == 2) const Spacer(flex: 1),
                for (final letter in rows[i]) ...[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _KeyCap(
                        letter,
                        onTap: onLetterTap == null
                            ? null
                            : () => onLetterTap!(letter),
                      ),
                    ),
                  ),
                ],
                if (i == 2) const Spacer(flex: 1),
              ],
            ),
            if (i < rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _KeyCap(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: .06)
              : Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

enum _ListeningColorMode { blue }

class _VoiceRecitationPracticeCard extends StatefulWidget {
  final String targetText;
  final _ListeningColorMode colorMode;
  final void Function(bool passed) onCompleted;

  const _VoiceRecitationPracticeCard({
    required this.targetText,
    required this.colorMode,
    required this.onCompleted,
  });

  @override
  State<_VoiceRecitationPracticeCard> createState() =>
      _VoiceRecitationPracticeCardState();
}

class _VoiceRecitationPracticeCardState
    extends State<_VoiceRecitationPracticeCard>
    with SingleTickerProviderStateMixin {
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  String _recognized = '';
  int _currentBlock = 0;
  int? _lastWrongAt;
  int _attemptsRemaining = 5;

  late List<String> _targetBlocks;
  late List<bool> _blockSolved;
  final _audioRecorder = AudioRecorder();
  // Grabación por STREAM en memoria (ver _FogStep / ReadAloud): evita el stop()
  // colgado del `record` en macOS y el archivo que no se escribe hasta stop().
  StreamSubscription<Uint8List>? _pcmSub;
  final BytesBuilder _pcmBuffer = BytesBuilder();

  bool _isModelDownloaded = false;
  bool _isDownloadingModel = false;
  bool _isModelInitializing = true;
  double _modelDownloadProgress = 0.0;
  String _modelStatus = '';
  String? _recordedPath;
  bool _finalizing = false;
  Timer? _autoStopTimer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _targetBlocks = _splitIntoBlocks(widget.targetText);
    _blockSolved = List<bool>.filled(_targetBlocks.length, false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _checkModelStatus();
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant _VoiceRecitationPracticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText) {
      _targetBlocks = _splitIntoBlocks(widget.targetText);
      _blockSolved = List<bool>.filled(_targetBlocks.length, false);
      _currentBlock = 0;
      _recognized = '';
      _attemptsRemaining = 5;
      _completed = false;
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
    }
  }

  Future<void> _initWhisper() async {
    setState(() {
      _isModelInitializing = true;
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
      debugPrint('Whisper init error in recitation: $e');
      if (mounted) {
        setState(() {
          _isModelInitializing = false;
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
      setState(() => _ready = available);
    } catch (e) {
      debugPrint('Recitation recorder init failed: $e');
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
    _pcmSub?.cancel();
    _pcmSub = null;
    unawaited(_audioRecorder
        .stop()
        .timeout(const Duration(seconds: 1), onTimeout: () => null)
        .catchError((Object _) => null)
        .whenComplete(_audioRecorder.dispose));
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
      _listening = true;
      _recognized = '';
    });

    _autoStopTimer?.cancel();
    if (_currentBlock < _targetBlocks.length) {
      final blockText = _targetBlocks[_currentBlock];
      final words = blockText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final limitSeconds = ((words / 1.5).ceil() + 6).clamp(8, 90);
      _autoStopTimer = Timer(Duration(seconds: limitSeconds), () {
        if (mounted && _listening) {
          _finishCapture();
        }
      });
    }
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordedPath =
            '${dir.path}/recit_${DateTime.now().millisecondsSinceEpoch}.wav';
        _pcmBuffer.clear();
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
        _pcmSub?.cancel();
        _pcmSub = stream.listen(
          (chunk) => _pcmBuffer.add(chunk),
          onError: (Object e) => debugPrint('[Recit] PCM stream error: $e'),
        );
        _pulse.repeat();
      }
    } catch (e) {
      debugPrint('Recitation Audio Recorder Error: $e');
      if (mounted) setState(() => _listening = false);
    }
  }

  Future<void> _finishCapture() async {
    if (_finalizing) return;
    _finalizing = true;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _pulse.stop();
    _pulse.value = 0;
    if (mounted) {
      setState(() {
        _listening = false;
        _recognized = 'Analizando tu voz...';
      });
    }
    try {
      // Corta el stream y suelta el micrófono sin bloquear (stop() puede
      // colgarse en macOS); el audio ya está en _pcmBuffer.
      await _pcmSub?.cancel();
      _pcmSub = null;
      unawaited(_audioRecorder
          .stop()
          .timeout(const Duration(seconds: 2), onTimeout: () => null)
          .catchError((Object _) => null));

      final pcmBytes = _pcmBuffer.toBytes();
      _pcmBuffer.clear();
      if (!mounted) return;
      if (pcmBytes.isEmpty || _recordedPath == null) {
        setState(() => _recognized = '');
        return;
      }

      final wavFile = File(_recordedPath!);
      await wavFile.parent.create(recursive: true);
      final builder = BytesBuilder()
        ..add(_buildWavHeader(pcmBytes.length))
        ..add(pcmBytes);
      await wavFile.writeAsBytes(builder.toBytes());

      final text = await WhisperService.instance.transcribe(_recordedPath!);
      _evaluateBlock(text);
    } catch (e) {
      debugPrint('Error transcribing recitation: $e');
      if (mounted) {
        setState(() {
          _listening = false;
          _recognized = 'Error: $e';
        });
      }
    } finally {
      _finalizing = false;
    }
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

  void _evaluateBlock(String text) {
    if (!mounted) return;
    if (text.isEmpty) {
      setState(() {
        _recognized = 'No se escuchó nada, intenta de nuevo.';
      });
      return;
    }

    final target = _targetBlocks[_currentBlock];
    final isMatch = _blocksMatch(text, target);

    if (isMatch) {
      setState(() {
        _blockSolved[_currentBlock] = true;
        _currentBlock += 1;
        _recognized = text;
      });
      HapticFeedback.lightImpact();

      if (_currentBlock >= _targetBlocks.length) {
        _completed = true;
        widget.onCompleted(true);
      }
    } else {
      setState(() {
        _attemptsRemaining -= 1;
        _lastWrongAt = DateTime.now().millisecondsSinceEpoch;
        _recognized = text;
      });
      HapticFeedback.heavyImpact();

      if (_attemptsRemaining <= 0) {
        widget.onCompleted(false);
      }
    }
  }

  bool _blocksMatch(String spoken, String expected) {
    if (spoken == expected) return true;
    if (spoken.contains(expected) || expected.contains(spoken)) return true;
    final spokenWords = spoken.split(' ').where((w) => w.isNotEmpty).toList();
    final expectedWords = expected
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (spokenWords.isEmpty || expectedWords.isEmpty) return false;
    int matchCount = 0;
    for (final expectedWord in expectedWords) {
      for (final spokenWord in spokenWords) {
        if (_wordsSimilar(spokenWord, expectedWord)) {
          matchCount++;
          break;
        }
      }
    }
    final matchRatio = matchCount / expectedWords.length;
    return matchRatio >= 0.5;
  }

  bool _wordsSimilar(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen <= 1) return a == b;
    int distance = 0;
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) distance++;
    }
    distance += (maxLen - minLength);
    final similarity = 1 - (distance / maxLen);
    return similarity >= 0.5;
  }

  List<String> _splitIntoBlocks(String text) {
    final words = _studyWords(text);
    if (words.length <= 6) return words;
    final blockSize = (words.length / 3).round().clamp(2, 5);
    final blocks = <String>[];
    for (var i = 0; i < words.length; i += blockSize) {
      final end = (i + blockSize).clamp(0, words.length);
      blocks.add(words.sublist(i, end).join(' '));
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isModelDownloaded) {
      final downloadPercent = (_modelDownloadProgress * 100).round();
      final isBlue = widget.colorMode == _ListeningColorMode.blue;
      final accent = isBlue ? RefColors.cyan : RefColors.pink;
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
        radius: 18,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Badge de Componente del Sistema
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withValues(alpha: .25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
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
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accent.withValues(alpha: .20),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.memory_rounded,
                color: accent,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Motor de Voz de Alta Precisión',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RefColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Optimiza la app con reconocimiento de voz avanzado. Permite transcribir y recitar tus versos palabra por palabra de forma inmediata, segura y privada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RefColors.muted,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),

            if (_isDownloadingModel || _isModelInitializing) ...[
              Text(
                _isModelInitializing
                    ? 'Configurando módulo...'
                    : 'Preparando motor: $downloadPercent%',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
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
              GestureDetector(
                onTap: _downloadModels,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: isBlue ? RefColors.cool : RefColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .20),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Activar Reconocimiento de Voz',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
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
                  const Text(
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
                  const Text(
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
      );
    }

    final isBlue = widget.colorMode == _ListeningColorMode.blue;
    final accent = _completed
        ? RefColors.lime
        : isBlue
        ? RefColors.cyan
        : RefColors.pink;
    final wrongRecent =
        _lastWrongAt != null &&
        DateTime.now().millisecondsSinceEpoch - _lastWrongAt! < 1200;
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _targetBlocks.length; i++)
                    _RecitationBlock(
                      text: _targetBlocks[i],
                      solved: _blockSolved[i],
                      active: i == _currentBlock && !_completed,
                      accent: accent,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_listening)
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, _) {
                                final t = _pulse.value;
                                return Container(
                                  width: 50 + 12 * t,
                                  height: 50 + 12 * t,
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
                            width: 48,
                            height: 48,
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
                              _listening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: RefColors.ink,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        _listening
                            ? 'Escuchando tu voz...'
                            : (_recognized.isEmpty ? 'Toca el mic y recita' : _recognized),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: (_recognized.isEmpty && !_listening)
                              ? RefColors.dim
                              : RefColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
                      children: [
                        Text(
                          '$_attemptsRemaining',
                          style: TextStyle(
                            color: _attemptsRemaining <= 1
                                ? RefColors.urgent
                                : accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'intentos',
                          style: TextStyle(
                            color: accent.withValues(alpha: .85),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'restantes',
                          style: TextStyle(
                            color: accent.withValues(alpha: .85),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_listening) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: .12),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _ListeningWaveIndicator(color: accent),
                      const SizedBox(height: 8),
                      const Text(
                        'Grabando voz...',
                        style: TextStyle(
                          color: RefColors.dim,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (_isModelInitializing)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: accent, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  'Preparando motor de voz...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecitationBlock extends StatelessWidget {
  final String text;
  final bool solved;
  final bool active;
  final Color accent;

  const _RecitationBlock({
    required this.text,
    required this.solved,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = solved
        ? RefColors.lime
        : active
        ? accent
        : RefColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: blockColor.withValues(alpha: solved || active ? .16 : .06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: blockColor.withValues(alpha: .6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (solved) ...[
            const Icon(Icons.check_rounded, color: RefColors.lime, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            solved ? text : '_' * text.length.clamp(3, 20),
            style: TextStyle(
              color: solved ? RefColors.lime : RefColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

