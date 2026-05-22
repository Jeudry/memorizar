// AUTO-GENERATED extraction from ui_screens.dart (refactor PR-D).
// Tightly-coupled exercise-flow widgets — kept in this library to
// preserve cross-class private visibility.
part of '../ui_screens.dart';

class _BlocksCounterCard extends StatelessWidget {
  const _BlocksCounterCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '2 / 4',
                  style: TextStyle(
                    color: RefColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: ' en su lugar'),
              ],
            ),
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          RefChip('Intento 1/3', dense: true),
        ],
      ),
    );
  }
}

class _BlocksListCard extends StatelessWidget {
  const _BlocksListCard();

  @override
  Widget build(BuildContext context) {
    final blocks = _studyBlocks(context);
    return Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            _VerseBlock(
              blocks[i],
              correct: i < 2,
              selected: i == 2,
              wrong: i == 3,
            ),
            if (i != blocks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

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

class _BlockMoveTarget extends StatelessWidget {
  final bool visible;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<int> onAccept;

  const _BlockMoveTarget({
    required this.visible,
    required this.active,
    required this.onTap,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => active,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final shown = visible || highlighted;
        return GestureDetector(
          onTap: active ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: shown ? 34 : 6,
            margin: EdgeInsets.symmetric(vertical: shown ? 6 : 2),
            padding: shown
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: RefColors.cyan.withValues(alpha: highlighted ? .20 : .10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: RefColors.cyan.withValues(
                  alpha: shown ? (highlighted ? .72 : .42) : 0,
                ),
              ),
            ),
            child: shown
                ? Center(
                    child: Text(
                      'Mover aquí',
                      style: TextStyle(
                        color: active
                            ? RefColors.cyan
                            : RefColors.cyan.withValues(alpha: .45),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
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

class _CompleteStatsCard extends StatelessWidget {
  final bool level2;
  final String firstValue;
  final String firstLabel;
  final String secondValue;
  final String secondLabel;
  final String timeValue;

  const _CompleteStatsCard({
    this.level2 = false,
    this.firstValue = '1/3',
    this.firstLabel = 'HUECOS',
    this.secondValue = '2/2',
    this.secondLabel = 'INTENTOS',
    this.timeValue = '00:45',
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 15),
      gradient: LinearGradient(
        colors: const [Color(0x55372B86), Color(0x668B5B21)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FlashStat(firstValue, firstLabel),
          _FlashStat(secondValue, secondLabel),
          if (level2)
            _FlashStat(timeValue, 'TIEMPO', valueColor: RefColors.sun),
        ],
      ),
    );
  }
}

class _CompleteSentenceCard extends StatelessWidget {
  final bool level2;

  const _CompleteSentenceCard({this.level2 = false});

  @override
  Widget build(BuildContext context) {
    final text = _maskedStudyLine(context, visibleWords: level2 ? 1 : 3);
    return Glass(
      padding: EdgeInsets.symmetric(
        horizontal: level2 ? 14 : 18,
        vertical: level2 ? 32 : 34,
      ),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .32),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          height: 1.6,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WordBankCard extends StatelessWidget {
  final bool level2;

  const _WordBankCard({this.level2 = false});

  @override
  Widget build(BuildContext context) {
    final base = _studyWords(_cardStudyText(context)).take(level2 ? 8 : 5);
    final words = [...base, if (level2) 'camino' else 'guía', 'padre'];
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.glassSoft,
      child: Column(
        children: [
          const Text(
            'ELIGE LA PALABRA CORRECTA',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [for (final word in words) _WordChip(word)],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;

  const _WordChip(this.label, {this.active = false, this.correct = false});

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (active || correct)
            ? accent.withValues(alpha: .14)
            : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (correct) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: RefColors.lime,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FirstLetterSentence extends StatelessWidget {
  final String? text;
  final int level;
  final List<String>? targets;
  final List<String?>? answers;
  final int activeIndex;
  final ValueChanged<int>? onBlankTap;

  const _FirstLetterSentence({
    this.text,
    required this.level,
    this.targets,
    this.answers,
    this.activeIndex = 0,
    this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHarder = level >= 2;
    final sourceText = text ?? _cardStudyText(context);
    final words = _studyWords(sourceText);
    final targetWords =
        targets ?? _firstLetterTargets(sourceText, level: level);
    final answerWords =
        answers ?? List<String?>.filled(targetWords.length, null);
    final visibleWords = switch (level) {
      1 => 3,
      2 => 1,
      _ => 0,
    };
    final usedTargetIndexes = <int>{};
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 32),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .30),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Center(
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
                  words[wordIndex],
                  usedTargetIndexes,
                  targetWords,
                  answerWords,
                ),
            const Text(
              '.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterWidget(
    String word,
    Set<int> usedTargetIndexes,
    List<String> targetWords,
    List<String?> answerWords,
  ) {
    final targetIndex = _matchingUnusedTargetIndex(
      word,
      usedTargetIndexes,
      targetWords,
    );
    if (targetIndex == null) return _LetterWord(word);
    usedTargetIndexes.add(targetIndex);
    return _LetterBlank(
      answer: answerWords[targetIndex],
      active: activeIndex == targetIndex && answerWords[targetIndex] == null,
      wordLength: word.length,
      onTap: () => onBlankTap?.call(targetIndex),
    );
  }

  int? _matchingUnusedTargetIndex(
    String word,
    Set<int> usedTargetIndexes,
    List<String> targetWords,
  ) {
    for (var index = 0; index < targetWords.length; index++) {
      if (usedTargetIndexes.contains(index)) continue;
      if (_sameAnswer(word, targetWords[index])) return index;
    }
    return null;
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

class _LetterBlank extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final complete = answer != null;
    final accent = complete
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    final length = wordLength.clamp(1, 14);
    return GestureDetector(
      onTap: complete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: .35)
              : accent.withValues(alpha: complete ? .16 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: active ? 1.0 : .5),
            width: active ? 2.4 : 1.5,
          ),
          boxShadow: active
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
          answer ?? '_' * length,
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

enum _ListeningColorMode { blue, pink }

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
    extends State<_VoiceRecitationPracticeCard> {
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
  Timer? _blockTimer;

  @override
  void initState() {
    super.initState();
    _targetBlocks = _splitIntoBlocks(widget.targetText);
    _blockSolved = List<bool>.filled(_targetBlocks.length, false);
    _initRecorder();
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

  Future<void> _initRecorder() async {
    try {
      final available = await _audioRecorder.hasPermission();
      if (!mounted) return;
      setState(() => _ready = available);
    } catch (e) {
      debugPrint('Recitation recorder init failed: $e');
    }
  }

  void _startSimulatedBlocks() {
    _blockTimer?.cancel();
    // Resuelve un bloque cada 2.2 segundos para simular una recitación fluida
    const blockDuration = Duration(milliseconds: 2200);

    _blockTimer = Timer.periodic(blockDuration, (timer) {
      if (!mounted || !_listening || _completed) {
        timer.cancel();
        return;
      }

      if (_currentBlock < _targetBlocks.length) {
        final solvedIndex = _currentBlock;
        setState(() {
          _blockSolved[solvedIndex] = true;
          _currentBlock += 1;
          _recognized = _targetBlocks[solvedIndex];
        });

        if (_currentBlock >= _targetBlocks.length) {
          timer.cancel();
          _completed = true;
          _stopAndCancelSimulation(passed: true);
        }
      }
    });
  }

  Future<void> _stopAndCancelSimulation({required bool passed}) async {
    _blockTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Error stopping recitation recorder: $e');
    }
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (passed) {
        _completed = true;
      }
    });
    widget.onCompleted(passed);
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    _audioRecorder.stop().then((_) => _audioRecorder.dispose());
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initRecorder();
      return;
    }
    if (_listening) {
      await _stopAndCancelSimulation(passed: false);
      return;
    }
    setState(() {
      _listening = true;
      _recognized = '';
    });
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recit_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        _startSimulatedBlocks();
      }
    } catch (e) {
      debugPrint('Recitation Audio Recorder Error: $e');
      if (mounted) setState(() => _listening = false);
    }
  }

  void _stopListeningOnComplete() {
    if (mounted) setState(() => _listening = false);
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
      child: Column(
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: _listening ? .55 : .18),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: .85)),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .35),
                        blurRadius: _listening ? 28 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: RefColors.ink,
                    size: 28,
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
                    _recognized.isEmpty
                        ? (_listening ? 'Escuchando…' : 'Toca el mic y recita')
                        : _recognized,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _recognized.isEmpty
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

class _ListeningHud extends StatelessWidget {
  final _ListeningColorMode colorMode;

  const _ListeningHud({required this.colorMode});

  @override
  Widget build(BuildContext context) {
    final isBlue = colorMode == _ListeningColorMode.blue;
    final accent = isBlue ? RefColors.cyan : RefColors.pink;
    final icon = isBlue ? '🎧' : '🎤';
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: .45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Empieza a recitar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '● ESCUCHANDO...',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceHiddenWordsCard extends StatelessWidget {
  final bool finalMode;

  const _VoiceHiddenWordsCard({required this.finalMode});

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    if (finalMode) {
      return _buildAllHidden(words);
    }
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 60000);
    final hiddenRatio = 0.35;
    final hiddenCount = (words.length * hiddenRatio).round().clamp(
      1,
      words.length - 1,
    );
    final indices = List.generate(words.length, (i) => i);
    indices.shuffle(rng);
    final hiddenIndices = indices.take(hiddenCount).toSet();
    return Glass(
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
                  for (var i = 0; i < words.length; i++)
                    if (hiddenIndices.contains(i))
                      _HiddenWord(
                        wordLength: words[i].length,
                        active: false,
                        pink: false,
                      )
                    else
                      _LetterWord(words[i]),
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
    );
  }

  Widget _buildAllHidden(List<String> words) {
    return Glass(
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
                  for (var i = 0; i < words.length; i++)
                    _HiddenWord(
                      wordLength: words[i].length,
                      active: i == 0,
                      pink: true,
                    ),
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
    );
  }
}

class _HiddenWord extends StatelessWidget {
  final int wordLength;
  final bool active;
  final bool pink;
  final bool solved;
  final bool skipped;
  final bool wrongFlash;
  final String? word;

  const _HiddenWord({
    required this.wordLength,
    this.active = false,
    this.pink = false,
    this.solved = false,
    this.skipped = false,
    this.wrongFlash = false,
    this.word,
  });

  @override
  Widget build(BuildContext context) {
    final accent = wrongFlash
        ? RefColors.urgent
        : skipped
        ? RefColors.sun
        : solved
        ? RefColors.lime
        : active
        ? (pink ? RefColors.pink : RefColors.cyan)
        : RefColors.border;
    final filledColor = skipped ? RefColors.sun : RefColors.lime;
    final length = wordLength.clamp(1, 14);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: wrongFlash ? .28 : (solved || active ? .16 : .08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: wrongFlash ? 1 : .62),
          width: wrongFlash ? 2 : 1.5,
        ),
      ),
      child: solved && word != null
          ? TweenAnimationBuilder<double>(
              key: ValueKey('solved-$word-$skipped'),
              tween: Tween(begin: 0.55, end: 1.0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                word!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: filledColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
              '_' * length,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _QuizNav extends StatelessWidget {
  const _QuizNav();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++) ...[
            Expanded(child: _QuizChip('Q$i', active: i == 2)),
            if (i < 5) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _QuizChip extends StatelessWidget {
  final String label;
  final bool active;

  const _QuizChip(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  RefColors.cyan.withValues(alpha: .92),
                  const Color(0xFF347DFF).withValues(alpha: .92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? RefColors.cyan : RefColors.border,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : RefColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;

  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.pink.withValues(alpha: .10),
      border: Border.all(color: RefColors.pink.withValues(alpha: .36)),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
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
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GlyphIcon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: RefColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTopBar extends StatelessWidget {
  final String center;

  const _ExerciseTopBar({required this.center});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Inside the exercise flow the back arrow jumps to the progress
          // tree (the user's "session map"), not the previous step. Use
          // pushReplacement so we don't pile new entries on the stack.
          RefBackButton(
            onTap: () => Navigator.pushReplacementNamed(
              context,
              '${AppRoutes.flow}/progress-tree',
            ),
          ),
          Expanded(child: Center(child: RefChip(center, dense: true))),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String ctx;
  final String? turn;
  final String question;
  final List<(String, String, bool)> options;

  const _QuestionCard({
    required this.ctx,
    this.turn,
    required this.question,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Glass(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ctx,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RefColors.muted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (turn != null)
                    Text(
                      turn!,
                      style: const TextStyle(
                        color: RefColors.sun,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              radius: 16,
              padding: const EdgeInsets.all(12),
              color: opt.$3
                  ? RefColors.pink.withValues(alpha: .14)
                  : RefColors.glass,
              border: Border.all(
                color: opt.$3
                    ? RefColors.pink.withValues(alpha: .45)
                    : RefColors.border,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: opt.$3 ? RefColors.primary : null,
                      color: opt.$3 ? null : RefColors.glassStrong,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        opt.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      opt.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

