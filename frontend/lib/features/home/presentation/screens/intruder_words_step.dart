import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_state.dart';
import '../../../../core/services/ai_quiz_models.dart';
import '../../../../core/services/local_llm_service.dart';
import '../../../../core/theme/ref_colors.dart';
import '../../../../core/ui/widgets.dart';

enum _IntruderPhase { selectLevel, loadingLlm, playing, result }

class IntruderWordsBody extends StatefulWidget {
  final MemoryCardData card;
  final VoidCallback onFinished;
  final int? level;

  const IntruderWordsBody({
    super.key,
    required this.card,
    required this.onFinished,
    this.level,
  });

  @override
  State<IntruderWordsBody> createState() => _IntruderWordsBodyState();
}

class _IntruderWordsBodyState extends State<IntruderWordsBody> {
  late _IntruderPhase _phase = widget.level != null
      ? _IntruderPhase.loadingLlm
      : _IntruderPhase.selectLevel;
  int _level = 1; // 1, 2, or 3
  String _loadingText = 'Despertando la IA local…';
  String? _errorMessage;

  IntruderVerseSet? _intruderSet;
  List<String> _alteredWords = [];
  final Set<int> _selectedIndices = {};

  int _lives = 3;
  int _secondsLeft = 30;
  Timer? _countdownTimer;
  Timer? _loadingTextTimer;
  bool _success = false;

  final List<String> _loadingMessages = [
    'Despertando la IA local…',
    'Analizando estructura teológica…',
    'Sembrando palabras intrusas sutiles…',
    'Alterando conectores y sinónimos…',
    'Preparando la cacería de errores…',
  ];
  int _loadingMsgIdx = 0;

  @override
  void initState() {
    super.initState();
    if (widget.level != null) {
      _level = widget.level!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateVerse();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  void _startLoadingMessages() {
    _loadingMsgIdx = 0;
    _loadingText = _loadingMessages[0];
    _loadingTextTimer?.cancel();
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted && _phase == _IntruderPhase.loadingLlm) {
        setState(() {
          _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMessages.length;
          _loadingText = _loadingMessages[_loadingMsgIdx];
        });
      }
    });
  }

  Future<void> _generateVerse() async {
    setState(() {
      _phase = _IntruderPhase.loadingLlm;
      _errorMessage = null;
    });
    _startLoadingMessages();

    final llm = LocalLlmService.instance;
    try {
      await llm.initLlm();
      if (!mounted) return;

      final set = await llm.generateIntruderVerse(
        reference: widget.card.front,
        verseText: widget.card.back,
        level: _level,
      );

      if (!mounted) return;

      setState(() {
        _intruderSet = set;
        _alteredWords = _splitWords(set.alteredVerse);
        _selectedIndices.clear();
        _lives = _level == 1 ? 3 : (_level == 2 ? 2 : 1);
        _secondsLeft = 30;
        _phase = _IntruderPhase.playing;
      });

      if (_level == 3) {
        _startTimer();
      }
    } catch (e) {
      debugPrint('Error generando palabras intrusas con IA local: $e');
      if (!mounted) return;
      setState(() {
        _phase = _IntruderPhase.selectLevel;
        _errorMessage =
            'No se pudo generar el ejercicio. Asegúrate de tener el modelo descargado e inténtalo de nuevo.';
      });
    } finally {
      _loadingTextTimer?.cancel();
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_phase != _IntruderPhase.playing) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
          _triggerFailure(reason: '¡Tiempo agotado!');
        }
      });
    });
  }

  List<String> _splitWords(String text) {
    final clean = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return const [];
    return clean.split(' ');
  }

  String _normalize(String word) {
    return word.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúüñ0-9]'), '');
  }

  void _toggleWordSelection(int index) {
    if (_phase != _IntruderPhase.playing) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (_selectedIndices.length < _level) {
          _selectedIndices.add(index);
        }
      }
    });
  }

  void _checkAnswers() {
    if (_intruderSet == null) return;
    final normalizedIntruders =
        _intruderSet!.intruderWords.map(_normalize).toSet();

    final List<int> correctIntruderIndices = [];
    for (var i = 0; i < _alteredWords.length; i++) {
      if (normalizedIntruders.contains(_normalize(_alteredWords[i]))) {
        correctIntruderIndices.add(i);
      }
    }

    final isCorrect = _selectedIndices.length == correctIntruderIndices.length &&
        _selectedIndices.every((idx) => correctIntruderIndices.contains(idx));

    if (isCorrect) {
      _countdownTimer?.cancel();
      HapticFeedback.mediumImpact();
      setState(() {
        _success = true;
        _phase = _IntruderPhase.result;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _lives--;
        _selectedIndices.clear();
      });

      if (_lives <= 0) {
        _countdownTimer?.cancel();
        _triggerFailure(reason: 'Te has quedado sin intentos.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incorrecto. Te quedan $_lives ${_lives == 1 ? 'intento' : 'intentos'}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: RefColors.urgent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _triggerFailure({required String reason}) {
    setState(() {
      _success = false;
      _phase = _IntruderPhase.result;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reason,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: RefColors.urgent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLevelCard({
    required int level,
    required String title,
    required String desc,
    required String livesText,
    required String timeText,
  }) {
    final isSelected = _level == level;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _level = level);
      },
      child: Glass(
        color: isSelected
            ? RefColors.glassStrong.withValues(alpha: .5)
            : RefColors.glass,
        border: isSelected
            ? Border.all(color: RefColors.cyan, width: 2)
            : Border.all(color: RefColors.border),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? RefColors.cyan : RefColors.ink,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: RefColors.cyan,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12.5,
                color: RefColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite, size: 14, color: RefColors.pink),
                const SizedBox(width: 4),
                Text(
                  livesText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.timer, size: 14, color: RefColors.cyan),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelection() {
    if (widget.level != null && _errorMessage != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: RefColors.urgent,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Error de Generación',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: RefColors.muted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Cta(
              'Reintentar Nivel $_level',
              onTap: _generateVerse,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RefColors.primary,
              ),
              child: const Icon(
                Icons.search,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Palabras Intrusas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'La IA local ha saboteado el versículo alterando algunas palabras. Encuéntralas antes de que se agoten tus intentos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: RefColors.muted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RefColors.urgent.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RefColors.urgent),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: RefColors.urgent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          _buildLevelCard(
            level: 1,
            title: 'Nivel 1: Principiante',
            desc: 'La IA cambia exactamente 1 palabra. La alteración es sutil pero plausible.',
            livesText: '3 intentos',
            timeText: 'Sin límite de tiempo',
          ),
          const SizedBox(height: 14),
          _buildLevelCard(
            level: 2,
            title: 'Nivel 2: Intermedio',
            desc: 'La IA cambia exactamente 2 palabras. Las alteraciones son muy parecidas al texto original.',
            livesText: '2 intentos',
            timeText: 'Sin límite de tiempo',
          ),
          const SizedBox(height: 14),
          _buildLevelCard(
            level: 3,
            title: 'Nivel 3: Experto',
            desc: 'La IA cambia exactamente 3 palabras sutiles (conectores o gramática). Solo una vida y tiempo límite.',
            livesText: '1 intento',
            timeText: 'Límite: 30 segundos',
          ),
          const SizedBox(height: 32),
          Cta(
            'Iniciar Cacería',
            onTap: _generateVerse,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: RefColors.cyan),
            const SizedBox(height: 24),
            Text(
              _loadingText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gemma 4 está procesando…',
              style: TextStyle(
                fontSize: 10.5,
                color: RefColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RefColors.glassStrong,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RefColors.border),
                ),
                child: Text(
                  'Nivel $_level',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: RefColors.cyan,
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < (_level == 1 ? 3 : (_level == 2 ? 2 : 1)); i++)
                    Icon(
                      Icons.favorite,
                      size: 20,
                      color: i < _lives ? RefColors.pink : RefColors.border,
                    ),
                ],
              ),
              if (_level == 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _secondsLeft < 10
                        ? RefColors.urgent.withValues(alpha: .2)
                        : RefColors.glassStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _secondsLeft < 10 ? RefColors.urgent : RefColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: _secondsLeft < 10 ? RefColors.urgent : RefColors.cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_secondsLeft}s',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _secondsLeft < 10 ? RefColors.urgent : RefColors.ink,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              widget.card.front,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: RefColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Glass(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: Text(
                          'Selecciona las palabras falsas:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: RefColors.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 10,
                        children: List.generate(_alteredWords.length, (idx) {
                          final word = _alteredWords[idx];
                          final isSelected = _selectedIndices.contains(idx);
                          return InkWell(
                            onTap: () => _toggleWordSelection(idx),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? RefColors.cyan.withValues(alpha: .25)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? RefColors.cyan
                                      : RefColors.border.withValues(alpha: .3),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                word,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? RefColors.cyan
                                      : RefColors.ink,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Cta(
            'Comprobar (${_selectedIndices.length}/$_level)',
            onTap: _selectedIndices.length == _level ? _checkAnswers : null,
            disabled: _selectedIndices.length != _level,
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_success) {
      final originalWords = _splitWords(widget.card.back);
      final intruderNorm =
          _intruderSet?.intruderWords.map(_normalize).toSet() ?? {};
      // Alineación palabra a palabra entre original y alterado (mismo nº de
      // palabras porque el ejercicio sólo reemplaza, no agrega/quita).
      final aligned = originalWords.length == _alteredWords.length;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RefColors.success,
                ),
                child: const Icon(
                  Icons.check,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                '¡Excelente Cacería!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Has purificado ${widget.card.front} en Nivel $_level.',
                style: const TextStyle(
                  fontSize: 13,
                  color: RefColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CORRECCIÓN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: RefColors.lime,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Un solo texto: cada palabra falsa va tachada y encima, en
                  // verde, la palabra verdadera (alineadas por la base, así el
                  // versículo se lee corrido abajo con las correcciones arriba).
                  Wrap(
                    spacing: 6,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: List.generate(_alteredWords.length, (i) {
                      final altered = _alteredWords[i];
                      final isIntruder = intruderNorm.contains(_normalize(altered));
                      if (!isIntruder) {
                        return Text(
                          altered,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: RefColors.ink,
                          ),
                        );
                      }
                      final correct = aligned ? originalWords[i] : '';
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (correct.isNotEmpty)
                            Text(
                              correct,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: Colors.greenAccent,
                              ),
                            ),
                          Text(
                            altered,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: RefColors.pink,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Cta(
              'Continuar',
              onTap: widget.onFinished,
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: RefColors.urgent,
                ),
                child: const Icon(
                  Icons.close,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '¡Cacería Fallida!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Las palabras intrusas han saboteado el versículo con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: RefColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Cta(
              'Reintentar Nivel $_level',
              onTap: _generateVerse,
            ),
            if (widget.level == null) ...[
              const SizedBox(height: 14),
              GhostButton(
                'Cambiar Dificultad',
                onTap: () {
                  setState(() {
                    _phase = _IntruderPhase.selectLevel;
                  });
                },
              ),
            ],
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _IntruderPhase.selectLevel:
        return _buildLevelSelection();
      case _IntruderPhase.loadingLlm:
        return _buildLoading();
      case _IntruderPhase.playing:
        return _buildGameplay();
      case _IntruderPhase.result:
        return _buildResult();
    }
  }
}
