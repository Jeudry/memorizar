import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/app_state.dart';
import '../../../../core/theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/presentation/widgets/reference_page.dart';
import '../../../../core/presentation/widgets/cta_button.dart';
import '../../../../core/presentation/widgets/ghost_button.dart';
import '../../../../core/presentation/widgets/glass.dart';
import '../../../../core/utils/text_utils.dart';
import '../widgets/flow/flow_headers.dart';
import '../widgets/flow/blocks_list_card.dart';
import '../widgets/flow/blocks_counter_card.dart';
import '../../../../core/presentation/widgets/status_chip.dart';

class ExerciseFlowData {
  final String slug;
  final String title;
  final String subtitle;

  const ExerciseFlowData(this.slug, this.title, this.subtitle);
}

const flowScreens = [
  ExerciseFlowData('01-escuchar', 'Escuchar', 'Primero absorbe la idea'),
  ExerciseFlowData('02-lectura-frag', 'Lectura fragmentada', 'Divide y repite'),
  ExerciseFlowData('03-leer-voz', 'Leer en voz', 'Activa memoria auditiva'),
  ExerciseFlowData('04-escuchar-voz', 'Escuchar voz', 'Reconoce sin mirar'),
  ExerciseFlowData('05-bloques', 'Bloques', 'Ordena piezas clave'),
  ExerciseFlowData('06-completar-n1', 'Completar N1', 'Recuerdo con apoyo'),
  ExerciseFlowData(
    '07-primera-letra-n1',
    'Primera letra N1',
    'Menos pistas, más memoria',
  ),
  ExerciseFlowData('08-voz-guiada', 'Voz guiada', 'Responde en voz alta'),
  ExerciseFlowData('09-quiz', 'Quiz', 'Elige la respuesta correcta'),
  ExerciseFlowData('10-completar-n2', 'Completar N2', 'Recuerdo más fuerte'),
  ExerciseFlowData('11-primera-letra-n2', 'Primera letra N2', 'Casi sin ayuda'),
  ExerciseFlowData('12-voz-final', 'Voz final', 'Demuestra dominio'),
  ExerciseFlowData('mini-review', 'Mini review', 'Cierre rápido'),
  ExerciseFlowData('final-review', 'Review final', 'Resumen de sesión'),
];

class ExerciseFlowScreen extends StatelessWidget {
  final ExerciseFlowData data;

  const ExerciseFlowScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _RealExerciseFlowScreen(data: data);
  }
}

class _RealExerciseFlowScreen extends StatefulWidget {
  final ExerciseFlowData data;

  const _RealExerciseFlowScreen({required this.data});

  @override
  State<_RealExerciseFlowScreen> createState() => _RealExerciseFlowScreenState();
}

class _RealExerciseFlowScreenState extends State<_RealExerciseFlowScreen> {
  int? _selected;
  bool _checked = false;
  int _fragmentVisibleWords = 8;
  List<String>? _blocksOrder;
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _letterController = TextEditingController();

  @override
  void didUpdateWidget(_RealExerciseFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.slug != widget.data.slug) {
      _blocksOrder = null;
      _checked = false;
      _selected = null;
      _answerController.clear();
      _letterController.clear();
      _fragmentVisibleWords = 8;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _letterController.dispose();
    super.dispose();
  }

  void _revealFragment(String slug, int totalWords) {
    if (totalWords <= 0) return;
    setState(() {
      _fragmentVisibleWords = (_fragmentVisibleWords + 8).clamp(1, totalWords);
      if (_fragmentVisibleWords >= totalWords) {
        AppScope.of(context).markExerciseStepCompleted(slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final slug = widget.data.slug;

    if (slug == 'final-review') return _RealFinalReview(store: store);
    if (slug == 'mini-review') return _RealPairingReview(store: store);

    final step = _flowStepNumber(slug);
    if (slug == '02-lectura-frag' && store.isExerciseStepCompleted(slug)) {
      _fragmentVisibleWords = studyWords(card.back).length;
    }

    return ReferencePage(
      showBottomNav: false,
      scrollable: slug != '01-escuchar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowStepHeader(
            step: '$step',
            title: _realStepTitle(slug),
            progress: step.clamp(1, 12),
          ),
          if (slug == '01-escuchar')
            Expanded(child: _realExerciseBody(context, store, card, deck, slug))
          else
            _realExerciseBody(context, store, card, deck, slug),
          const SizedBox(height: 14),
          _realExerciseFooter(context, store, card, deck, slug),
        ],
      ),
    );
  }

  Widget _realExerciseBody(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    if (slug == '01-escuchar') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ListenAudioCard(
              onCompleted: () => store.markExerciseStepCompleted(slug),
            ),
          ),
        ],
      );
    }

    if (slug == '02-lectura-frag') {
      final totalWords = studyWords(card.back).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressiveFragmentCard(
            visibleWords: _fragmentVisibleWords,
            onTap: () => _revealFragment(slug, totalWords),
          ),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '🧠',
            text: 'Divide y vencerás: tu cerebro procesa mejor grupos de 7-8 palabras. Cada vez que tocas, revelas una "pieza" nueva hasta completar el puzzle mental.',
          ),
        ],
      );
    }

    if (slug == '03-leer-voz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadAloudPracticeCard(
            targetText: card.back,
            source: card.front,
            onCompleted: (recognized, audioPath) {
              store.saveVoiceReadForCurrentCard(recognized);
              if (audioPath != null) {
                store.saveVoiceAudioPathForCurrentCard(audioPath);
              }
              store.markExerciseStepCompleted(slug);
            },
          ),
        ],
      );
    }

    if (slug == '04-escuchar-voz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ListenOwnVoicePracticeCard(
            originalText: card.back,
            voiceText: store.voiceReadForCurrentCard(),
            audioPath: store.voiceAudioPathForCurrentCard(),
            source: card.front,
            onCompleted: () => store.markExerciseStepCompleted(slug),
          ),
        ],
      );
    }

    if (slug == '08-voz-guiada' || slug == '12-voz-final') {
      final hidden = slug == '12-voz-final';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: hidden,
            firstValue: hidden ? '0/7' : '3/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS',
            timeValue: hidden ? '00:30' : '00:45',
          ),
          const SizedBox(height: 14),
          _VoiceHiddenWordsCard(finalMode: hidden),
          const SizedBox(height: 14),
          _ListeningHud(
            colorMode: hidden
                ? _ListeningColorMode.pink
                : _ListeningColorMode.blue,
          ),
          const SizedBox(height: 14),
          _FlowHintCard(
            icon: '🎤',
            text:
                'Recítalo completo y marca honestamente si salió literal. Aquí la app simula la práctica de voz hasta integrar grabación real.',
          ),
        ],
      );
    }

    if (slug == '05-bloques') {
      final blocks = _orderedBlocks(card.back);
      _blocksOrder ??= _rotatedBlocks(blocks);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocksCounterCard(
            correct: _blocksOrder?.where((b) => _orderedBlocks(card.back)[_blocksOrder!.indexOf(b)] == b).length ?? 0,
            total: _orderedBlocks(card.back).length,
          ),
          const SizedBox(height: 14),
          BlocksListCard(
            blocks: _blocksOrder ?? [],
            correctOrder: _orderedBlocks(card.back),
            checked: _checked,
            onReorder: (newOrder) {
              setState(() {
                _blocksOrder = newOrder;
                _checked = false;
              });
            },
          ),
          if (_checked)
            _InlineResult(
              correct: listEquals(_blocksOrder, _orderedBlocks(card.back)),
              text: listEquals(_blocksOrder, _orderedBlocks(card.back))
                  ? '¡Perfecto! El orden es correcto.'
                  : 'Orden incorrecto. Prueba de nuevo.',
            ),
        ],
      );
    }

    if (slug == '06-completar-n1' || slug == '10-completar-n2') {
      final level2 = slug == '10-completar-n2';
      final target = _targetWord(card.back, level2: level2);
      final words = _completionOptions(card.back, target);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: level2,
            firstValue: level2 ? '1/5' : '1/3',
            firstLabel: 'HUECOS',
            secondValue: _checked ? '1/2' : '2/2',
            secondLabel: 'INTENTOS',
            timeValue: level2 ? '00:45' : '00:45',
          ),
          const SizedBox(height: 14),
          _StudyPromptCard(
            label: card.front,
            text: _maskedOneWord(card.back, target),
          ),
          const SizedBox(height: 14),
          Glass(
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
                  children: [
                    for (final word in words)
                      GestureDetector(
                        onTap: () => setState(() {
                          _answerController.text = word;
                          _checked = false;
                        }),
                        child: _WordChip(word),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            onChanged: (_) => setState(() => _checked = false),
            style: const TextStyle(
              color: RefColors.ink,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe o toca la palabra que falta',
              hintStyle: const TextStyle(color: RefColors.dim),
              filled: true,
              fillColor: RefColors.glassSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_checked)
            _InlineResult(
              correct: _sameAnswer(_answerController.text, target),
              text: _sameAnswer(_answerController.text, target)
                  ? 'Correcto.'
                  : 'La palabra era: $target',
            ),
        ],
      );
    }

    if (slug == '07-primera-letra-n1' || slug == '11-primera-letra-n2') {
      final level2 = slug == '11-primera-letra-n2';
      final answer = _firstLetterAnswer(card.back, level2: level2);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: level2,
            firstValue: level2 ? '1/5' : '1/3',
            firstLabel: 'LETRAS',
            secondValue: _checked ? '1/2' : '2/2',
            secondLabel: 'INTENTOS',
          ),
          const SizedBox(height: 12),
          _FirstLetterSentence(level: level2 ? 2 : 1),
          const SizedBox(height: 14),
          TextField(
            controller: _letterController,
            onChanged: (_) => setState(() => _checked = false),
            style: const TextStyle(
              color: RefColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText:
                  'Escribe las iniciales: ${answer.replaceAll(RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '•')}',
              hintStyle: const TextStyle(color: RefColors.dim),
              filled: true,
              fillColor: RefColors.glassSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _KeyboardCard(),
          if (_checked)
            _InlineResult(
              correct: _sameAnswer(_letterController.text, answer),
              text: _sameAnswer(_letterController.text, answer)
                  ? 'Iniciales correctas.'
                  : 'Iniciales esperadas: $answer',
            ),
        ],
      );
    }

    final options = _quizOptions(deck, card);
    final selectedCard = _selected == null ? null : options[_selected!];
    final isCorrect = selectedCard?.id == card.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _QuizNav(),
        const SizedBox(height: 14),
        _ExerciseQuestionBlock(
          contextLabel: deck.isBible ? card.source : deck.title.toUpperCase(),
          question: '¿Qué texto corresponde a ${card.front}?',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < options.length; i++) ...[
          _ExerciseOption(
            letter: String.fromCharCode(65 + i),
            title: options[i].back,
            tip: options[i].front,
            selected: _selected == i,
            onTap: () => setState(() {
              _selected = i;
              _checked = false;
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (_checked)
          _InlineResult(
            correct: isCorrect,
            text: isCorrect ? 'Correcto.' : 'Respuesta correcta: ${card.back}',
          ),
      ],
    );
  }

  Widget _realExerciseFooter(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    final next = _nextFlowSlug(slug);
    final completed = store.isExerciseStepCompleted(slug);
    if (slug == '02-lectura-frag') {
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Reiniciar',
              onTap: () => setState(() {
                _fragmentVisibleWords = 4;
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CtaButton(
              completed ? 'Siguiente →' : 'Revela todo para continuar',
              isEnabled: completed,
              onTap: () {
                Navigator.pushNamed(context, '${AppRoutes.flow}/$next');
              },
            ),
          ),
        ],
      );
    }
    if (slug == '01-escuchar' ||
        slug == '03-leer-voz' ||
        slug == '04-escuchar-voz') {
      return CtaButton(
        _footerLabel(slug, checked: _checked, completed: completed),
        isEnabled: completed,
        onTap: () => Navigator.pushNamed(context, '${AppRoutes.flow}/$next'),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: GhostButton(
            'Pista',
            onTap: () {
              if (slug == '05-bloques') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Primer bloque: ${_orderedBlocks(card.back).first}',
                    ),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pista: ${firstWords(card.back, 6)}')),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        if (kDebugMode && !completed && (slug.contains('voz') || slug.contains('leer'))) ...[
          Expanded(
            child: GhostButton(
              'Skip (Dev)',
              onTap: () {
                store.markExerciseStepCompleted(slug);
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: CtaButton(
            _footerLabel(slug, checked: _checked, completed: completed),
            isEnabled: _footerEnabled(
              slug,
              checked: _checked,
              completed: completed,
            ),
            onTap: () {
              if (_isPassiveStep(slug)) {
                if (!completed) {
                  store.markExerciseStepCompleted(slug);
                  return;
                }
                if (slug == '12-voz-final') store.answerCurrentCard(true);
                Navigator.pushNamed(context, '${AppRoutes.flow}/$next');
                return;
              }
              if (!_checked) {
                setState(() => _checked = true);
                return;
              }
              final correct = _currentStepCorrect(slug, card, deck);
              if (slug == '09-quiz' || slug == '12-voz-final') {
                store.answerCurrentCard(correct);
              }
              store.markExerciseStepCompleted(slug);
              Navigator.pushNamed(context, '${AppRoutes.flow}/$next');
            },
          ),
        ),
      ],
    );
  }

  bool _currentStepCorrect(
    String slug,
    MemoryCardData card,
    MemoryDeckData deck,
  ) {
    if (slug == '05-bloques') {
      final blocks = _orderedBlocks(card.back);
      return listEquals(_blocksOrder, blocks);
    }
    if (slug == '06-completar-n1' || slug == '10-completar-n2') {
      return _sameAnswer(
        _answerController.text,
        _targetWord(card.back, level2: slug == '10-completar-n2'),
      );
    }
    if (slug == '07-primera-letra-n1' || slug == '11-primera-letra-n2') {
      return _sameAnswer(
        _letterController.text,
        _firstLetterAnswer(card.back, level2: slug == '11-primera-letra-n2'),
      );
    }
    if (slug == '09-quiz') {
      final options = _quizOptions(deck, card);
      return _selected != null && options[_selected!].id == card.id;
    }
    return true;
  }

  String _footerLabel(
    String slug, {
    required bool checked,
    required bool completed,
  }) {
    if (slug == '01-escuchar') {
      return completed ? 'Siguiente →' : 'Escucha completa requerida';
    }
    if (slug == '03-leer-voz') {
      return completed ? 'Siguiente →' : 'Lee en voz alta para continuar';
    }
    if (slug == '04-escuchar-voz') {
      return completed ? 'Siguiente →' : 'Escucha tu lectura para continuar';
    }
    if (_isPassiveStep(slug)) {
      return completed ? 'Siguiente →' : 'Marcar terminado';
    }
    return checked ? 'Siguiente →' : 'Comprobar →';
  }

  bool _footerEnabled(
    String slug, {
    required bool checked,
    required bool completed,
  }) {
    if (slug == '01-escuchar') return completed;
    if (slug == '04-escuchar-voz') return completed;
    return true;
  }

  int _flowStepNumber(String slug) {
    final match = RegExp(r'^(\d+)').firstMatch(slug);
    if (match == null) return slug == 'mini-review' ? 13 : 14;
    return int.parse(match.group(1)!);
  }

  String _realStepTitle(String slug) {
    if (slug == '01-escuchar') return 'Escuchar';
    if (slug == '02-lectura-frag') return 'Lectura fragmentada';
    if (slug == '03-leer-voz') return 'Leer en voz';
    if (slug == '04-escuchar-voz') return 'Escuchar tu voz';
    if (slug.contains('bloques')) return 'Ordena el texto';
    if (slug.contains('completar')) return 'Completa memoria';
    if (slug.contains('primera-letra')) return 'Iniciales';
    if (slug.contains('quiz')) return 'Quiz real';
    if (slug.contains('voz')) return 'Recitación';
    return 'Estudio activo';
  }

  String _nextFlowSlug(String current) {
    final idx = flowScreens.indexWhere((s) => s.slug == current);
    if (idx == -1 || idx == flowScreens.length - 1) return 'final-review';
    return flowScreens[idx + 1].slug;
  }

  bool _isPassiveStep(String slug) {
    return slug == '01-escuchar' ||
        slug == '02-lectura-frag' ||
        slug == '03-leer-voz' ||
        slug == '04-escuchar-voz' ||
        slug.contains('voz');
  }

  List<MemoryCardData> _quizOptions(MemoryDeckData deck, MemoryCardData card) {
    final others = deck.cards.where((c) => c.id != card.id).toList();
    others.shuffle();
    final options = [card, ...others.take(2)];
    options.shuffle();
    return options;
  }

  List<String> _orderedBlocks(String text) {
    final words = studyWords(text);
    final size = words.length > 18 ? 4 : 3;
    final blocks = <String>[];
    for (var i = 0; i < words.length; i += size) {
      blocks.add(words.skip(i).take(size).join(' '));
    }
    return blocks.take(5).toList();
  }

  List<String> _rotatedBlocks(List<String> blocks) {
    if (blocks.length < 2) return blocks;
    return [...blocks.skip(1), blocks.first];
  }

  String _targetWord(String text, {required bool level2}) {
    final words = studyWords(text)
        .where(
          (word) =>
              word.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '').length > 3,
        )
        .toList();
    if (words.isEmpty) return studyWords(text).first;
    return words[(level2 ? words.length ~/ 2 : 0).clamp(0, words.length - 1)];
  }

  String _maskedOneWord(String text, String target) {
    return studyWords(
      text,
    ).map((word) => word == target ? '____' : word).join(' ');
  }

  List<String> _completionOptions(String text, String target) {
    final options = <String>[target];
    for (final word in studyWords(text)) {
      final clean = word.replaceAll(RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]'), '');
      if (clean.length > 3 && !options.contains(clean)) options.add(clean);
      if (options.length >= 5) break;
    }
    return options;
  }

  String _firstLetterAnswer(String text, {required bool level2}) {
    final words = studyWords(text).skip(level2 ? 1 : 3).take(level2 ? 6 : 4);
    return words.map((word) => word.substring(0, 1)).join('');
  }

  bool _sameAnswer(String a, String b) {
    return normalizeText(a) == normalizeText(b);
  }
}

class _InlineResult extends StatelessWidget {
  final bool correct;
  final String text;

  const _InlineResult({required this.correct, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        padding: const EdgeInsets.all(12),
        color: (correct ? RefColors.lime : RefColors.urgent).withValues(
          alpha: .12,
        ),
        border: Border.all(
          color: (correct ? RefColors.lime : RefColors.urgent).withValues(
            alpha: .45,
          ),
        ),
        child: Text(
          '${correct ? '✓' : '×'} $text',
          style: TextStyle(
            color: correct ? RefColors.lime : RefColors.urgent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProgressiveFragmentCard extends StatelessWidget {
  final int visibleWords;
  final VoidCallback onTap;

  const _ProgressiveFragmentCard({
    required this.visibleWords,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final words = studyWords(cardStudyText(context));
    final safeVisible = visibleWords.clamp(0, words.length);
    final store = AppScope.of(context);
    final source = store.activeDeck.isBible
        ? '${cardSourceText(context)} · RV1909'
        : cardSourceText(context);
    return GestureDetector(
      onTap: safeVisible >= words.length ? null : onTap,
      child: Glass(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .22),
            RefColors.cyan.withValues(alpha: .10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                source,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Toca para aclarar lo siguiente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (var i = 0; i < words.length; i++)
                  i < safeVisible
                      ? Text(
                          words[i],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: RefColors.ink,
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 20,
                          decoration: BoxDecoration(
                            color: RefColors.glassSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
  String _recognized = '';
  String _status = 'Toca el micrófono y lee el texto.';
  double _score = 0;
  final _audioRecorder = AudioRecorder();
  String? _recordedPath;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _status = 'No pude escuchar bien. Intenta otra vez.';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _ready = available;
      _status = available
          ? 'Toca el micrófono y lee el texto.'
          : 'Activa permiso de micrófono para leer en voz.';
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _audioRecorder.stop().then((_) => _audioRecorder.dispose());
    super.dispose();
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      if (_listening) {
        _audioRecorder.stop();
        _grade(_recognized);
      }
      setState(() => _listening = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initSpeech();
      return;
    }
    if (_listening) {
      await _speech.stop();
      await _audioRecorder.stop();
      if (mounted) setState(() => _listening = false);
      _grade(_recognized);
      return;
    }
    setState(() {
      _recognized = '';
      _score = 0;
      _completed = false;
      _listening = true;
      _isStarting = true;
      _status = 'Escuchando... lee el texto completo.';
    });
    
    try {
      await _speech.listen(
        localeId: 'es_ES',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10),
        onResult: _handleResult,
      );
    } catch (e) {
      debugPrint('STT Listen Error: $e');
      _isStarting = false;
      if (mounted) setState(() => _listening = false);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (!_listening || !_isStarting) return;
    _isStarting = false;


    if (await _audioRecorder.hasPermission()) {
      try {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        _recordedPath = path;
      } catch (e) {
        debugPrint('Audio Recorder Error: $e');
      }
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    final score = speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _recognized = recognized;
      _score = score;
      if (passed) {
        _completed = true;
        _status = '60% o más está fino. Puedes avanzar.';
      }
    });
    if (passed) {
      _stopAndComplete(recognized);
    }
  }

  Future<void> _stopAndComplete(String recognized) async {
    final path = await _audioRecorder.stop();
    if (path != null) _recordedPath = path;
    widget.onCompleted(recognized, _recordedPath);
  }

  void _grade(String recognized) {
    final score = speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _score = score;
      _completed = passed;
      _status = passed
          ? '60% o más está fino. Puedes avanzar.'
          : 'Se parece poco todavía. Reintenta leyendo más completo.';
    });
    if (passed) {
      _stopAndComplete(recognized);
    }
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
          padding: const EdgeInsets.all(18),
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
              Text(
                widget.targetText,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: RefColors.glassSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RefColors.border),
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
              const SizedBox(height: 16),
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
                        _Progress(_score.clamp(.02, 1.0)),
                        const SizedBox(height: 7),
                        Text(
                          _status,
                          style: const TextStyle(
                            color: RefColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _stopAndComplete(widget.targetText),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: RefColors.pink.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: RefColors.pink.withValues(alpha: .3)),
                              ),
                              child: const Text(
                                'DEBUG: SKIP RECORDING',
                                style: TextStyle(
                                  color: RefColors.pink,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
          if (!_playing) _highlightedCount = 0;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _audioDuration.inMilliseconds > 0 && _playing) {
        final progress = position.inMilliseconds / _audioDuration.inMilliseconds;
        setState(() {
          _highlightedCount = (progress * _currentText.length).toInt().clamp(0, _currentText.length);
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
      await _audioPlayer.play(DeviceFileSource(widget.audioPath!));
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
      padding: const EdgeInsets.all(18),
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
                color: RefColors.glassSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RefColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VoiceTab(
                    'Original',
                    active: _tab == 0,
                    onTap: () => _switchTab(0),
                  ),
                  const SizedBox(width: 4),
                  _VoiceTab(
                    'Tuyo',
                    active: _tab == 1,
                    onTap: () => _switchTab(1),
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
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RefColors.border),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: _tab == 1 && !hasVoice ? RefColors.dim : RefColors.ink.withValues(alpha: 0.4),
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
                  TextSpan(
                    text: _currentText.substring(_highlightedCount),
                  ),
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
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onCompleted,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: RefColors.pink.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RefColors.pink.withValues(alpha: .3)),
                ),
                child: const Text(
                  'DEBUG: SKIP PLAYBACK',
                  style: TextStyle(
                    color: RefColors.pink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
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
      final index = studyWords(
        before,
      ).length.clamp(0, studyWords(text).length);
      final absoluteIndex = (_ttsStartWordOffset + index).clamp(
        0,
        studyWords(cardStudyText(context)).length,
      );
      setState(() => _wordIndex = absoluteIndex);
      _scrollToProgress(
        absoluteIndex,
        studyWords(cardStudyText(context)).length,
      );
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _textScrollController.dispose();
    super.dispose();
  }

  void _scrollToProgress(int index, int total) {
    if (total <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_textScrollController.hasClients) return;
      final max = _textScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final target = max * (index / (total - 1)).clamp(0.0, 1.0);
      _textScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
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
    final words = studyWords(text);
    final start = _wordIndex.clamp(0, words.length - 1);
    _ttsStartWordOffset = start;
    final remaining = words.skip(start).join(' ');
    await _tts.speak(remaining);
  }

  Future<void> _skipForward(String text) async {
    final words = studyWords(text);
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

  @override
  Widget build(BuildContext context) {
    final words = studyWords(cardStudyText(context));
    final source = cardSourceText(context).toUpperCase();
    final text = cardStudyText(context);
    final safeIndex = _wordIndex.clamp(0, words.length - 1);
    final lead = words.take(safeIndex).join(' ');
    final current = words[safeIndex];
    final tail = words.skip(safeIndex + 1).join(' ');
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
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 34),
          Expanded(
            child: Center(
              child: Scrollbar(
                controller: _textScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _textScrollController,
                  padding: const EdgeInsets.only(right: 10),
                  child: Text.rich(
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
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _Progress(progress.clamp(.03, 1.0)),
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
          const SizedBox(height: 20),
          Container(height: 1, color: RefColors.inner),
          const SizedBox(height: 18),
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: RefColors.glassSoft,
          shape: BoxShape.circle,
          border: Border.all(color: RefColors.border),
        ),
        child: Icon(icon, size: 20, color: RefColors.ink),
      ),
    );
  }
}

class _PlayerMainButton extends StatelessWidget {
  final bool paused;
  final VoidCallback? onTap;

  const _PlayerMainButton({required this.paused, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          gradient: RefColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x44273CFE),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 38,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final double value;
  const _Progress(this.value);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        backgroundColor: RefColors.inner,
        valueColor: const AlwaysStoppedAnimation(RefColors.lime),
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
      padding: const EdgeInsets.all(16),
      color: RefColors.glassSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String text;
  const _WordChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RefColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: RefColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FirstLetterSentence extends StatelessWidget {
  final int level;
  const _FirstLetterSentence({required this.level});

  @override
  Widget build(BuildContext context) {
    final text = cardStudyText(context);
    final words = studyWords(text);
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 6,
        runSpacing: 10,
        children: [
          for (var i = 0; i < words.length; i++)
            if ((level == 1 && i < 3) || (level == 2 && i < 1))
              Text(
                words[i],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: RefColors.ink,
                ),
              )
            else
              Text(
                '${words[i][0]}${'_' * (words[i].length - 1)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: RefColors.dim,
                  letterSpacing: 1.2,
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
  final String? timeValue;

  const _CompleteStatsCard({
    required this.level2,
    required this.firstValue,
    required this.firstLabel,
    required this.secondValue,
    required this.secondLabel,
    this.timeValue,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      gradient: LinearGradient(
        colors: [
          (level2 ? RefColors.pink : RefColors.violet).withValues(alpha: .15),
          RefColors.cyan.withValues(alpha: .05),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(firstValue, firstLabel, level2 ? RefColors.pink : RefColors.violet),
          _Stat(secondValue, secondLabel, RefColors.sun),
          if (timeValue != null)
            _Stat(timeValue!, 'TIEMPO', RefColors.cyan),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

enum _ListeningColorMode { blue, pink }

class _ListeningHud extends StatelessWidget {
  final _ListeningColorMode colorMode;
  const _ListeningHud({required this.colorMode});

  @override
  Widget build(BuildContext context) {
    final color = colorMode == _ListeningColorMode.blue ? RefColors.cyan : RefColors.pink;
    return Glass(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.mic_rounded, color: color, size: 38),
          const SizedBox(height: 12),
          const Text(
            'ESCUCHANDO...',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
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
    final text = cardStudyText(context);
    final words = studyWords(text);
    return Glass(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < words.length; i++)
            if (!finalMode && i < 3)
              Text(
                words[i],
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: RefColors.ink,
                ),
              )
            else
              Container(
                width: words[i].length * 10.0 + 10,
                height: 22,
                decoration: BoxDecoration(
                  color: RefColors.glassSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
        ],
      ),
    );
  }
}

class _StudyPromptCard extends StatelessWidget {
  final String label;
  final String text;

  const _StudyPromptCard({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardCard extends StatelessWidget {
  const _KeyboardCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(12),
      color: RefColors.glassSoft,
      child: Column(
        children: [
          const Text(
            'TECLADO DE INICIALES',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final char in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
                _Key(char),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String char;
  const _Key(this.char);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RefColors.border),
      ),
      child: Text(
        char,
        style: const TextStyle(
          color: RefColors.ink,
          fontSize: 14,
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
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: RefColors.lime,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: RefColors.inner,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: RefColors.inner,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseQuestionBlock extends StatelessWidget {
  final String contextLabel;
  final String question;

  const _ExerciseQuestionBlock({
    required this.contextLabel,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .2),
          RefColors.cyan.withValues(alpha: .1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            contextLabel,
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOption extends StatelessWidget {
  final String letter;
  final String title;
  final String tip;
  final bool selected;
  final VoidCallback onTap;

  const _ExerciseOption({
    required this.letter,
    required this.title,
    required this.tip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        padding: const EdgeInsets.all(16),
        color: selected ? RefColors.lime.withValues(alpha: .15) : RefColors.glassSoft,
        border: Border.all(
          color: selected ? RefColors.lime : RefColors.border,
          width: selected ? 2 : 1,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? RefColors.lime : RefColors.glassStrong,
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? Colors.white : RefColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tip,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealPairingReview extends StatefulWidget {
  final AppStore store;
  const _RealPairingReview({required this.store});

  @override
  State<_RealPairingReview> createState() => _RealPairingReviewState();
}

class _RealPairingReviewState extends State<_RealPairingReview> {
  int? _leftSelected;
  int? _rightSelected;
  final List<int> _matched = [];

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowStepHeader(
            step: '13',
            title: 'Emparejar conceptos',
            progress: 13,
          ),
          const SizedBox(height: 14),
          _PairMatchCard(
            leftSelected: _leftSelected,
            rightSelected: _rightSelected,
            matched: _matched,
            onLeftTap: (idx) => setState(() => _leftSelected = idx),
            onRightTap: (idx) {
              setState(() {
                _rightSelected = idx;
                if (_leftSelected == idx) {
                  _matched.add(idx);
                  _leftSelected = null;
                  _rightSelected = null;
                  HapticFeedback.lightImpact();
                }
              });
            },
          ),
          const SizedBox(height: 24),
          CtaButton(
            _matched.length == 3 ? 'Continuar →' : 'Une todas las piezas',
            isEnabled: _matched.length == 3,
            onTap: () {
              Navigator.pushNamed(
                context,
                '${AppRoutes.flow}/final-review',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PairMatchCard extends StatelessWidget {
  final int? leftSelected;
  final int? rightSelected;
  final List<int> matched;
  final Function(int) onLeftTap;
  final Function(int) onRightTap;

  const _PairMatchCard({
    required this.leftSelected,
    required this.rightSelected,
    required this.matched,
    required this.onLeftTap,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Row(
              children: [
                Expanded(
                  child: _MatchItem(
                    'Referencia $i',
                    selected: leftSelected == i,
                    matched: matched.contains(i),
                    onTap: () => onLeftTap(i),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MatchItem(
                    'Texto $i',
                    selected: rightSelected == i,
                    matched: matched.contains(i),
                    onTap: () => onRightTap(i),
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MatchItem extends StatelessWidget {
  final String text;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;

  const _MatchItem(this.text, {
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: matched ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: matched
              ? RefColors.lime.withValues(alpha: .15)
              : selected
                  ? RefColors.cyan.withValues(alpha: .15)
                  : RefColors.glassStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: matched
                ? RefColors.lime
                : selected
                    ? RefColors.cyan
                    : RefColors.border,
          ),
        ),
        child: Text(
          matched ? '✓' : text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: matched ? RefColors.lime : RefColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _RealFinalReview extends StatelessWidget {
  final AppStore store;
  const _RealFinalReview({required this.store});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowStepHeader(
            step: '14',
            title: 'Sesión completada',
            progress: 14,
          ),
          const SizedBox(height: 14),
          const _FinalScoreCard(),
          const SizedBox(height: 14),
          const _FinalVersesCard(),
          const SizedBox(height: 24),
          CtaButton(
            'Finalizar sesión',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (_) => false,
            ),
          ),
          const SizedBox(height: 12),
          const _ShareAchievementCard(),
        ],
      ),
    );
  }
}

class _FinalScoreCard extends StatelessWidget {
  const _FinalScoreCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(24),
      gradient: const LinearGradient(
        colors: [RefColors.violet, RefColors.cyan],
      ),
      child: Column(
        children: [
          const Text(
            '¡EXCELENTE TRABAJO!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '100%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 54,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'DOMINIO DEL TEXTO',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FinalStat('12', 'PASOS'),
              _FinalStat('04:15', 'TIEMPO'),
              _FinalStat('+50', 'XP'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalStat extends StatelessWidget {
  final String value;
  final String label;
  const _FinalStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FinalVersesCard extends StatelessWidget {
  const _FinalVersesCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TEXTOS REPASADOS',
            style: TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 1; i++) ...[
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Salmos 23:1',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 28, top: 4),
              child: Text(
                'Jehová es mi pastor; nada me faltará.',
                style: TextStyle(color: RefColors.muted, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareAchievementCard extends StatelessWidget {
  const _ShareAchievementCard();

  @override
  Widget build(BuildContext context) {
    return GhostButton(
      'Compartir logro',
      onTap: () {},
    );
  }
}
