import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/practice/data/models/answer_evaluation_result.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/exercise_performance_summary.dart';
import 'package:memorizar/features/practice/data/models/exercise_level.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_args.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_state.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_consolidations_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_session_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/practice_services_provider.dart';
import 'package:memorizar/features/practice/services/answer_evaluator_service.dart';
import 'package:memorizar/features/practice/services/understanding_exercise_service.dart';

class ExerciseSessionScreen extends ConsumerWidget {
  const ExerciseSessionScreen({
    super.key,
    required this.args,
    this.debugState,
  });

  final ExerciseSessionArgs args;
  final ExerciseSessionState? debugState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExerciseSessionState session = debugState ?? ref.watch(exerciseSessionProvider(args));
    final notifier = debugState == null ? ref.read(exerciseSessionProvider(args).notifier) : null;
    final deckAsync = ref.watch(deckByIdProvider(args.deckId));
    final deckItemsAsync = ref.watch(itemsForDeckProvider(args.deckId));
    final deck = deckAsync.valueOrNull;
    final deckItems = deckItemsAsync.valueOrNull ?? const <Item>[];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = deck != null
        ? AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length]
        : AppColors.indigo;

    if (session.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session.isFinished || session.currentItem == null || session.currentStep == null) {
      return _PracticeFinishedScreen(
        completed: session.completedItems.length,
        deckName: deck?.name ?? 'Deck',
        performanceSummaries: session.performanceSummaries,
        completedItems: session.completedItems,
        objective: session.objective,
        cooperativePlayers: session.cooperativePlayers,
        cooperativeMode: session.cooperativeMode,
        turnHandoffs: session.turnHandoffs,
        rescueCount: session.rescueCount,
        coachFeedback: session.coachFeedback,
        voiceFeedback: session.voiceFeedback,
        duelBestScore: session.duelBestScore,
      );
    }

    final item = session.currentItem!;
    final step = session.currentStep!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(session.planName ?? deck?.name ?? 'Memorizar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: ((session.currentItemIndex * session.steps.length) + session.currentStepIndex + 1) /
                (session.queue.length * session.steps.length),
            backgroundColor: cs.outline,
            valueColor: AlwaysStoppedAnimation(accent),
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ProgressHeader(session: session, step: step, item: item, accent: accent),
                const SizedBox(height: 20),
                if (session.lastEvaluation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _EvaluationBanner(result: session.lastEvaluation!, accent: accent),
                  ),
                _StepSwitcher(
                  key: ValueKey('${session.currentItemIndex}_${session.currentStepIndex}_${step.type.storageValue}'),
                  args: args,
                  item: item,
                  deckItems: deckItems,
                  step: step,
                  accent: accent,
                  difficulty: session.difficulty,
                  latestAudioPath: session.latestAudioPath,
                  latestTranscript: session.latestTranscript,
                  onComplete: ({
                    required double score,
                    required int mistakes,
                    Map<String, Object?>? payload,
                    AnswerEvaluationResult? evaluation,
                    String? transcript,
                    String? latestAudioPath,
                  }) {
                    if (notifier == null) return Future.value();
                    return notifier.completeCurrentStep(
                      score: score,
                      mistakes: mistakes,
                      payload: payload,
                      evaluation: evaluation,
                      transcript: transcript,
                      latestAudioPath: latestAudioPath,
                    );
                  },
                  onSaveAudio: notifier?.saveAudioClip ?? ((_, {durationMs = 0}) async {}),
                  onSetTranscript: notifier?.setTranscript ?? (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.session,
    required this.step,
    required this.item,
    required this.accent,
  });

  final ExerciseSessionState session;
  final ExerciseStep step;
  final Item item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: session.objective.label, color: AppColors.indigo),
              _InfoChip(label: session.difficulty.label, color: accent),
              if (session.cooperativePlayers > 1)
                _InfoChip(label: session.cooperativeMode.label, color: AppColors.warning),
              _InfoChip(label: step.type.label, color: AppColors.info),
              if (step.level != null) _InfoChip(label: step.level!.label, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 18),
          Text(item.front, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            step.instruction,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Item',
                  value: '${session.currentItemIndex + 1}/${session.queue.length}',
                  color: accent,
                ),
              ),
              if (session.cooperativePlayers > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: session.cooperativeMode == CooperativeMode.chain ? 'Cadena' : 'Turno',
                    value: 'Jugador ${session.currentTurnIndex + 1}',
                    color: AppColors.warning,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Paso',
                  value: '${session.currentStepIndex + 1}/${session.steps.length}',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if (session.cooperativePlayers > 1) ...[
            const SizedBox(height: 14),
            Text(
              session.rescuePending && session.cooperativeMode == CooperativeMode.rescue
                  ? 'Rescate activo: otro jugador continúa este mismo ejercicio.'
                  : session.cooperativeMode.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepSwitcher extends ConsumerWidget {
  const _StepSwitcher({
    super.key,
    required this.args,
    required this.item,
    required this.deckItems,
    required this.step,
    required this.accent,
    required this.difficulty,
    required this.onComplete,
    required this.onSaveAudio,
    required this.onSetTranscript,
    this.latestAudioPath,
    this.latestTranscript,
  });

  final ExerciseSessionArgs args;
  final Item item;
  final List<Item> deckItems;
  final ExerciseStep step;
  final Color accent;
  final MemorizationDifficulty difficulty;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;
  final Future<void> Function(String path, {int durationMs}) onSaveAudio;
  final void Function(String transcript) onSetTranscript;
  final String? latestAudioPath;
  final String? latestTranscript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (step.type) {
      case ExerciseStepType.listen:
      case ExerciseStepType.readAlong:
        return _IntroStepCard(
          item: item,
          step: step,
          accent: accent,
          onContinue: () => onComplete(score: 1, mistakes: 0),
        );
      case ExerciseStepType.reconstructBlocks:
        return _ReconstructBlocksStepCard(
          item: item,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.segmentedRecall:
        return _SegmentedRecallStepCard(
          item: item,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.thematicBlocks:
        return _ThematicBlocksStepCard(
          item: item,
          deckItems: deckItems,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.recordReading:
        return _RecordStepCard(
          item: item,
          accent: accent,
          onComplete: (path, durationMs) async {
            await onSaveAudio(path, durationMs: durationMs);
            await onComplete(
              score: 1,
              mistakes: 0,
              latestAudioPath: path,
              payload: {'path': path, 'durationMs': durationMs},
            );
          },
        );
      case ExerciseStepType.playRecording:
        return _PlaybackStepCard(
          path: latestAudioPath,
          accent: accent,
          onComplete: () => onComplete(
            score: latestAudioPath == null ? 0.5 : 1,
            mistakes: latestAudioPath == null ? 1 : 0,
            payload: {'played': latestAudioPath != null},
          ),
        );
      case ExerciseStepType.readHiddenWithVoice:
        return _HiddenReadingVoiceStepCard(
          item: item,
          step: step,
          accent: accent,
          latestTranscript: latestTranscript,
          onSetTranscript: onSetTranscript,
          onComplete: onComplete,
        );
      case ExerciseStepType.reverseReference:
        return _ReverseReferenceStepCard(
          item: item,
          deckItems: deckItems,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.compareVersions:
        return _CompareVersionsStepCard(
          item: item,
          deckItems: deckItems,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.cutIn:
        return _CutInStepCard(
          item: item,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.randomStart:
        return _RandomStartStepCard(
          item: item,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.fillOptions:
        return _FillOptionsStepCard(
          item: item,
          deckItems: deckItems,
          step: step,
          accent: accent,
          difficulty: difficulty,
          onComplete: onComplete,
        );
      case ExerciseStepType.typeFirstLetter:
        return _TypeFirstLetterStepCard(
          item: item,
          step: step,
          accent: accent,
          difficulty: difficulty,
          onComplete: onComplete,
        );
      case ExerciseStepType.understandingQuestion:
        return _UnderstandingQuestionStepCard(
          item: item,
          deckItems: deckItems,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.detectErrors:
        return _DetectErrorsStepCard(
          item: item,
          deckItems: deckItems,
          step: step,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.reciteFromMemoryVoice:
        return _VoiceMatchStepCard(
          item: item,
          step: step,
          accent: accent,
          latestTranscript: latestTranscript,
          onSetTranscript: onSetTranscript,
          onComplete: onComplete,
        );
      case ExerciseStepType.pressureRecall:
        return _PressureRecallStepCard(
          item: item,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.totalExam:
        return _TotalExamStepCard(
          item: item,
          accent: accent,
          onComplete: onComplete,
        );
      case ExerciseStepType.coachReview:
        return _CoachReviewStepCard(
          accent: accent,
          objective: args.objective,
          onContinue: () => onComplete(score: 1, mistakes: 0),
        );
    }
  }
}

class _CompareVersionsStepCard extends ConsumerStatefulWidget {
  const _CompareVersionsStepCard({
    required this.item,
    required this.deckItems,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final List<Item> deckItems;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_CompareVersionsStepCard> createState() => _CompareVersionsStepCardState();
}

class _ReverseReferenceStepCard extends ConsumerStatefulWidget {
  const _ReverseReferenceStepCard({
    required this.item,
    required this.deckItems,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final List<Item> deckItems;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_ReverseReferenceStepCard> createState() => _ReverseReferenceStepCardState();
}

class _ReverseReferenceStepCardState extends ConsumerState<_ReverseReferenceStepCard> {
  String? _selected;
  late final List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = {
      widget.item.front,
      ...widget.deckItems.where((candidate) => candidate.id != widget.item.id).take(3).map((candidate) => candidate.front),
    }.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Referencia inversa', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(widget.item.back, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          ..._options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VersionChoiceCard(
                label: 'Referencia',
                content: option,
                selected: _selected == option,
                accent: widget.accent,
                onTap: () => setState(() => _selected = option),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _selected == null
                ? null
                : () async {
                    final isCorrect = _selected == widget.item.front;
                    await widget.onComplete(
                      score: isCorrect ? 1 : 0.3,
                      mistakes: isCorrect ? 0 : 1,
                      payload: {'selectedReference': _selected, 'correctReference': widget.item.front},
                    );
                  },
            icon: const Icon(Icons.bookmark_added_rounded),
            label: const Text('Validar referencia'),
          ),
        ],
      ),
    );
  }
}

class _ThematicBlocksStepCard extends ConsumerStatefulWidget {
  const _ThematicBlocksStepCard({
    required this.item,
    required this.deckItems,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final List<Item> deckItems;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_ThematicBlocksStepCard> createState() => _ThematicBlocksStepCardState();
}

class _ThematicBlocksStepCardState extends ConsumerState<_ThematicBlocksStepCard> {
  String? _selected;
  late final String _correctTheme;
  late final List<String> _options;

  @override
  void initState() {
    super.initState();
    final normalizer = ref.read(textNormalizerProvider);
    final tokens = normalizer.tokenize(widget.item.back).where((token) => token.length > 3).take(2).toList();
    _correctTheme = widget.item.book != null ? widget.item.book! : (tokens.isEmpty ? 'Tema central' : tokens.join(' / '));
    _options = {
      _correctTheme,
      ...widget.deckItems.where((candidate) => candidate.id != widget.item.id).take(3).map((candidate) {
        final candidateTokens = normalizer.tokenize(candidate.back).where((token) => token.length > 3).take(2).toList();
        return candidate.book ?? (candidateTokens.isEmpty ? candidate.front : candidateTokens.join(' / '));
      }),
    }.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bloques temáticos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('¿En qué bloque encaja mejor este contenido?', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(widget.item.back, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: _selected == option,
                    selectedColor: widget.accent.withValues(alpha: 0.18),
                    onSelected: (_) => setState(() => _selected = option),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selected == null
                ? null
                : () async {
                    final isCorrect = _selected == _correctTheme;
                    await widget.onComplete(
                      score: isCorrect ? 1 : 0.45,
                      mistakes: isCorrect ? 0 : 1,
                      payload: {'selectedTheme': _selected, 'correctTheme': _correctTheme},
                    );
                  },
            icon: const Icon(Icons.category_rounded),
            label: const Text('Confirmar tema'),
          ),
        ],
      ),
    );
  }
}

class _TotalExamStepCard extends ConsumerStatefulWidget {
  const _TotalExamStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_TotalExamStepCard> createState() => _TotalExamStepCardState();
}

class _TotalExamStepCardState extends ConsumerState<_TotalExamStepCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Examen total', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Sin ayudas visibles. Escribe o dicta el contenido completo desde memoria.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Tu respuesta final',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final result = evaluator.evaluate(
                expected: widget.item.back,
                actual: _controller.text,
                level: ExerciseLevel.level3,
                maxMistakesOverride: 1,
              );
              await widget.onComplete(
                score: result.score,
                mistakes: result.mistakes,
                evaluation: result,
                payload: {'mode': 'total_exam'},
              );
            },
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Cerrar examen'),
          ),
        ],
      ),
    );
  }
}

class _CoachReviewStepCard extends StatelessWidget {
  const _CoachReviewStepCard({
    required this.accent,
    required this.objective,
    required this.onContinue,
  });

  final Color accent;
  final PracticeObjective objective;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: accent),
              const SizedBox(width: 10),
              Text('Coach IA', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            switch (objective) {
              PracticeObjective.quick => 'Sesión corta: nos interesa detectar si el ritmo te alcanza para sostener el recuerdo.',
              PracticeObjective.deep => 'Sesión profunda: el coach usará tus pasos fuertes y débiles para decirte por dónde seguir.',
              PracticeObjective.duel => 'Modo duelo: vamos a comparar este intento contra tu mejor marca reciente.',
              PracticeObjective.totalExam => 'Examen total: el feedback se enfocará en cierre, precisión y recuperación sin ayudas.',
              PracticeObjective.master => 'Modo maestro: mezclamos presión, arranques raros y menos ayudas para exigirte de verdad.',
            },
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ver feedback final'),
          ),
        ],
      ),
    );
  }
}

class _CutInStepCard extends ConsumerStatefulWidget {
  const _CutInStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_CutInStepCard> createState() => _CutInStepCardState();
}

class _CutInStepCardState extends ConsumerState<_CutInStepCard> {
  late final TextEditingController _controller;
  late final String _prompt;
  late final String _expected;

  @override
  void initState() {
    super.initState();
    final words = widget.item.back.split(RegExp(r'\s+'));
    final cutIndex = words.length > 4 ? words.length ~/ 2 : 1;
    _prompt = words.take(cutIndex).join(' ');
    _expected = words.skip(cutIndex).join(' ');
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    return _SimpleRecallCard(
      title: 'Modo corte',
      subtitle: 'Continúa desde aquí: $_prompt',
      controller: _controller,
      accent: widget.accent,
      buttonLabel: 'Validar continuación',
      expectedText: _expected,
      focusWords: _expected.split(RegExp(r'\s+')).take(2).toList(),
      onSubmit: () async {
        final result = evaluator.evaluate(
          expected: _expected,
          actual: _controller.text,
          level: ExerciseLevel.level2,
        );
        await widget.onComplete(
          score: result.score,
          mistakes: result.mistakes,
          evaluation: result,
          payload: {'prompt': _prompt},
        );
      },
    );
  }
}

class _RandomStartStepCard extends ConsumerStatefulWidget {
  const _RandomStartStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_RandomStartStepCard> createState() => _RandomStartStepCardState();
}

class _RandomStartStepCardState extends ConsumerState<_RandomStartStepCard> {
  late final TextEditingController _controller;
  late final String _startSnippet;
  late final String _expected;

  @override
  void initState() {
    super.initState();
    final words = widget.item.back.split(RegExp(r'\s+'));
    final startIndex = words.length > 5 ? words.length ~/ 3 : 0;
    _startSnippet = words.skip(startIndex).take(3).join(' ');
    _expected = words.skip(startIndex + 3).join(' ');
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    return _SimpleRecallCard(
      title: 'Arranque aleatorio',
      subtitle: 'Empieza justo después de: $_startSnippet',
      controller: _controller,
      accent: widget.accent,
      buttonLabel: 'Validar arranque',
      expectedText: _expected,
      focusWords: _startSnippet.split(RegExp(r'\s+')).toList(),
      onSubmit: () async {
        final result = evaluator.evaluate(
          expected: _expected,
          actual: _controller.text,
          level: ExerciseLevel.level2,
        );
        await widget.onComplete(
          score: result.score,
          mistakes: result.mistakes,
          evaluation: result,
          payload: {'startSnippet': _startSnippet},
        );
      },
    );
  }
}

class _PressureRecallStepCard extends ConsumerStatefulWidget {
  const _PressureRecallStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_PressureRecallStepCard> createState() => _PressureRecallStepCardState();
}

class _PressureRecallStepCardState extends ConsumerState<_PressureRecallStepCard> {
  late final TextEditingController _controller;
  int _secondsLeft = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    return _SimpleRecallCard(
      title: 'Modo presión',
      subtitle: 'Tienes $_secondsLeft segundos para escribir o dictar el contenido.',
      controller: _controller,
      accent: widget.accent,
      buttonLabel: _secondsLeft == 0 ? 'Tiempo agotado' : 'Cerrar presión',
      enabled: _secondsLeft > 0,
      expectedText: widget.item.back,
      onSubmit: () async {
        final result = evaluator.evaluate(
          expected: widget.item.back,
          actual: _controller.text,
          level: ExerciseLevel.level3,
        );
        await widget.onComplete(
          score: result.score,
          mistakes: result.mistakes,
          evaluation: result,
          payload: {'secondsLeft': _secondsLeft},
        );
      },
    );
  }
}

class _SimpleRecallCard extends StatelessWidget {
  const _SimpleRecallCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.accent,
    required this.buttonLabel,
    required this.onSubmit,
    this.enabled = true,
    this.expectedText,
    this.focusWords = const <String>[],
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final Color accent;
  final String buttonLabel;
  final Future<void> Function() onSubmit;
  final bool enabled;
  final String? expectedText;
  final List<String> focusWords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (expectedText != null) ...[
            const SizedBox(height: 14),
            _GradualHintBox(
              expectedText: expectedText!,
              accent: accent,
              focusWords: focusWords,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: enabled ? onSubmit : null,
            icon: const Icon(Icons.play_circle_rounded),
            label: Text(buttonLabel),
            style: FilledButton.styleFrom(backgroundColor: accent),
          ),
        ],
      ),
    );
  }
}

class _CompareVersionsStepCardState extends ConsumerState<_CompareVersionsStepCard> {
  String? _selected;
  late final CompareVersionsChallenge _challenge;

  @override
  void initState() {
    super.initState();
    final evaluator = ref.read(answerEvaluatorProvider);
    _challenge = evaluator.buildCompareVersionsChallenge(
      item: widget.item,
      deckItems: widget.deckItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compara las dos versiones.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Elige cuál refleja fielmente el contenido que estás memorizando.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          _VersionChoiceCard(
            label: 'Versión A',
            content: _challenge.versionA,
            selected: _selected == 'A',
            accent: widget.accent,
            onTap: () => setState(() => _selected = 'A'),
          ),
          const SizedBox(height: 14),
          _VersionChoiceCard(
            label: 'Versión B',
            content: _challenge.versionB,
            selected: _selected == 'B',
            accent: widget.accent,
            onTap: () => setState(() => _selected = 'B'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _selected == null
                ? null
                : () async {
                    final isCorrect = _selected == _challenge.correctVersion;
                    await widget.onComplete(
                      score: isCorrect ? 1 : 0.35,
                      mistakes: isCorrect ? 0 : 1,
                      payload: {
                        'selectedVersion': _selected,
                        'correctVersion': _challenge.correctVersion,
                      },
                    );
                  },
            icon: const Icon(Icons.compare_rounded),
            label: const Text('Validar versión'),
          ),
        ],
      ),
    );
  }
}

class _GradualHintBox extends StatefulWidget {
  const _GradualHintBox({
    required this.expectedText,
    required this.accent,
    this.focusWords = const <String>[],
  });

  final String expectedText;
  final Color accent;
  final List<String> focusWords;

  @override
  State<_GradualHintBox> createState() => _GradualHintBoxState();
}

class _GradualHintBoxState extends State<_GradualHintBox> {
  int _hintLevel = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hints = _buildHints(widget.expectedText, widget.focusWords);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: widget.accent, size: 18),
              const SizedBox(width: 8),
              Text('Pistas graduales', style: theme.textTheme.titleSmall),
              const Spacer(),
              OutlinedButton(
                onPressed: _hintLevel >= hints.length
                    ? null
                    : () => setState(() => _hintLevel = (_hintLevel + 1).clamp(0, hints.length)),
                child: Text(_hintLevel == 0 ? 'Ver pista' : 'Otra pista'),
              ),
            ],
          ),
          if (_hintLevel == 0)
            Text(
              'Si te trabas, aquí la app puede soltarte una pista pequeña sin regalarte todo.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72)),
            )
          else ...[
            const SizedBox(height: 10),
            for (final hint in hints.take(_hintLevel))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $hint', style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
  }

  List<String> _buildHints(String expectedText, List<String> focusWords) {
    final words = expectedText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final sanitizedFocus = focusWords.where((word) => word.trim().isNotEmpty).toList();
    final startPreview = words.take(words.length >= 3 ? 3 : words.length).join(' ');
    final endPreview = words.length >= 2 ? words.skip(words.length - 2).join(' ') : words.join(' ');
    return [
      'Son ${words.length} palabras${sanitizedFocus.isEmpty ? '' : ' y las palabras clave rondan: ${sanitizedFocus.join(', ')}'}.',
      if (startPreview.isNotEmpty) 'Empieza cerca de: $startPreview',
      if (endPreview.isNotEmpty && endPreview != startPreview) 'Cierra cerca de: $endPreview',
    ];
  }
}

class _UnderstandingQuestionStepCard extends ConsumerStatefulWidget {
  const _UnderstandingQuestionStepCard({
    required this.item,
    required this.deckItems,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final List<Item> deckItems;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_UnderstandingQuestionStepCard> createState() => _UnderstandingQuestionStepCardState();
}

class _UnderstandingQuestionStepCardState extends ConsumerState<_UnderstandingQuestionStepCard> {
  String? _selected;
  late final UnderstandingQuestionChallenge _challenge;

  @override
  void initState() {
    super.initState();
    final service = ref.read(understandingExerciseProvider);
    _challenge = service.buildQuestion(
      item: widget.item,
      deckItems: widget.deckItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: widget.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Pregunta de entendimiento', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fase IA local: preguntas generadas desde el contenido para reforzar comprensión.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(_challenge.question, style: theme.textTheme.titleSmall),
          const SizedBox(height: 14),
          ..._challenge.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VersionChoiceCard(
                  label: 'Opción',
                  content: option,
                  selected: _selected == option,
                  accent: widget.accent,
                  onTap: () => setState(() => _selected = option),
                ),
              )),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _selected == null
                ? null
                : () async {
                    final isCorrect = _selected == _challenge.correctAnswer;
                    await widget.onComplete(
                      score: isCorrect ? 1 : 0.45,
                      mistakes: isCorrect ? 0 : 1,
                      payload: {
                        'question': _challenge.question,
                        'selectedAnswer': _selected,
                        'correctAnswer': _challenge.correctAnswer,
                        'explanation': _challenge.explanation,
                      },
                    );
                  },
            icon: const Icon(Icons.quiz_rounded),
            label: const Text('Responder'),
          ),
        ],
      ),
    );
  }
}

class _ReconstructBlocksStepCard extends ConsumerStatefulWidget {
  const _ReconstructBlocksStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_ReconstructBlocksStepCard> createState() => _ReconstructBlocksStepCardState();
}

class _ReconstructBlocksStepCardState extends ConsumerState<_ReconstructBlocksStepCard> {
  late final BlockReconstructionChallenge _challenge;
  late List<String> _available;
  final List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    final evaluator = ref.read(answerEvaluatorProvider);
    _challenge = evaluator.buildBlockReconstructionChallenge(widget.item);
    _available = [..._challenge.shuffledBlocks];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reconstruye el contenido por bloques.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Toca los bloques en el orden correcto para rearmar la frase.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text('Tu orden', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected.isEmpty
                  ? [
                      Text(
                        'Todavía no has colocado bloques.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
                      ),
                    ]
                  : _selected
                      .map((block) => InputChip(
                            label: Text(block),
                            selected: true,
                            onPressed: () {
                              setState(() {
                                _selected.remove(block);
                                _available.add(block);
                              });
                            },
                          ))
                      .toList(),
            ),
          ),
          const SizedBox(height: 18),
          Text('Bloques disponibles', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _available
                .map((block) => ActionChip(
                      label: Text(block),
                      backgroundColor: widget.accent.withValues(alpha: 0.12),
                      onPressed: () {
                        setState(() {
                          _available.remove(block);
                          _selected.add(block);
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _available = [..._challenge.shuffledBlocks];
                            _selected.clear();
                          });
                        },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reiniciar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _selected.length == _challenge.correctBlocks.length
                      ? () async {
                          final isCorrect = _selected.join('|') == _challenge.correctBlocks.join('|');
                          await widget.onComplete(
                            score: isCorrect ? 1 : 0.4,
                            mistakes: isCorrect ? 0 : 1,
                            payload: {'selectedBlocks': _selected, 'correctBlocks': _challenge.correctBlocks},
                          );
                        }
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Validar orden'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedRecallStepCard extends ConsumerStatefulWidget {
  const _SegmentedRecallStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_SegmentedRecallStepCard> createState() => _SegmentedRecallStepCardState();
}

class _SegmentedRecallStepCardState extends ConsumerState<_SegmentedRecallStepCard> {
  late final List<String> _segments;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final words = widget.item.back.split(RegExp(r'\s+'));
    _segments = [
      for (var i = 0; i < words.length; i += 4) words.skip(i).take(4).join(' '),
    ];
    _controllers.addAll(List.generate(_segments.length, (_) => TextEditingController()));
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Memorización por tramos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Completa cada tramo corto sin necesidad de recitar todo de una vez.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          _GradualHintBox(
            expectedText: widget.item.back,
            accent: widget.accent,
            focusWords: _segments.take(2).toList(),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _segments.length; i++) ...[
            Text('Tramo ${i + 1}', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _controllers[i],
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () async {
              var score = 0.0;
              var mistakes = 0;
              for (var i = 0; i < _segments.length; i++) {
                final result = evaluator.evaluate(
                  expected: _segments[i],
                  actual: _controllers[i].text,
                  level: ExerciseLevel.level2,
                );
                score += result.score;
                mistakes += result.mistakes;
              }
              await widget.onComplete(
                score: _segments.isEmpty ? 0 : score / _segments.length,
                mistakes: mistakes,
                payload: {'segments': _segments.length},
              );
            },
            icon: const Icon(Icons.segment_rounded),
            label: const Text('Validar tramos'),
          ),
        ],
      ),
    );
  }
}

class _HiddenReadingVoiceStepCard extends ConsumerStatefulWidget {
  const _HiddenReadingVoiceStepCard({
    required this.item,
    required this.step,
    required this.accent,
    required this.latestTranscript,
    required this.onSetTranscript,
    required this.onComplete,
  });

  final Item item;
  final ExerciseStep step;
  final Color accent;
  final String? latestTranscript;
  final void Function(String transcript) onSetTranscript;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_HiddenReadingVoiceStepCard> createState() => _HiddenReadingVoiceStepCardState();
}

class _HiddenReadingVoiceStepCardState extends ConsumerState<_HiddenReadingVoiceStepCard> {
  late final TextEditingController _controller;
  late final FillOptionsChallenge _challenge;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.latestTranscript);
    final evaluator = ref.read(answerEvaluatorProvider);
    _challenge = evaluator.buildFillOptionsChallenge(
      item: widget.item,
      deckItems: [widget.item],
      level: widget.step.level!,
      difficulty: MemorizationDifficulty.beginner,
      hiddenFractionOverride: widget.step.hiddenFractionOverride,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    final audio = ref.read(audioPracticeServiceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lee el contenido con palabras ocultas.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Usa el micrófono para leer lo que recuerdas y corrige la transcripción si hace falta.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _challenge.words.length; i++)
                Chip(
                  label: Text(
                    _challenge.hiddenIndexes.contains(i)
                        ? evaluator.maskWord(_challenge.words[i], widget.step.level!)
                        : _challenge.words[i],
                  ),
                  backgroundColor: _challenge.hiddenIndexes.contains(i)
                      ? widget.accent.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(height: 18),
          _GradualHintBox(
            expectedText: widget.item.back,
            accent: widget.accent,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'La lectura detectada aparecerá aquí…',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onSetTranscript,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_listening) {
                      await audio.stopListening();
                      setState(() => _listening = false);
                    } else {
                      final ok = await audio.startListening(
                        onResult: (transcript, isFinal) {
                          _controller.text = transcript;
                          widget.onSetTranscript(transcript);
                          if (isFinal && mounted) {
                            setState(() => _listening = false);
                          }
                        },
                      );
                      if (ok) {
                        setState(() => _listening = true);
                      }
                    }
                  },
                  icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(_listening ? 'Detener lectura' : 'Leer con micrófono'),
                  style: FilledButton.styleFrom(backgroundColor: _listening ? AppColors.error : widget.accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => audio.speak(widget.item.back),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Oír referencia'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GradualHintBox(
            expectedText: widget.item.back,
            accent: widget.accent,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final expectedTokens = ref.read(textNormalizerProvider).tokenize(widget.item.back);
              final maxMistakes = ((expectedTokens.length) * (widget.step.allowedMistakesRatioOverride ?? 0.3)).ceil();
              final result = evaluator.evaluate(
                expected: widget.item.back,
                actual: _controller.text,
                level: widget.step.level!,
                maxMistakesOverride: maxMistakes,
              );
              await widget.onComplete(
                score: result.score,
                mistakes: result.mistakes,
                payload: {
                  'transcript': _controller.text,
                  'hiddenFraction': widget.step.hiddenFractionOverride,
                  'allowedMistakesRatio': widget.step.allowedMistakesRatioOverride,
                },
                transcript: _controller.text,
                evaluation: result,
              );
            },
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Evaluar lectura'),
          ),
        ],
      ),
    );
  }
}

class _IntroStepCard extends ConsumerStatefulWidget {
  const _IntroStepCard({
    required this.item,
    required this.step,
    required this.accent,
    required this.onContinue,
  });

  final Item item;
  final ExerciseStep step;
  final Color accent;
  final Future<void> Function() onContinue;

  @override
  ConsumerState<_IntroStepCard> createState() => _IntroStepCardState();
}

class _IntroStepCardState extends ConsumerState<_IntroStepCard> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final audio = ref.read(audioPracticeServiceProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Icon(
            widget.step.type == ExerciseStepType.listen ? Icons.headphones_rounded : Icons.menu_book_rounded,
            size: 44,
            color: widget.accent,
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _started ? 1 : 0),
            duration: const Duration(milliseconds: 2200),
            builder: (context, value, _) {
              final total = widget.item.back.length;
              final visible = (total * value).round().clamp(0, total);
              return Text(
                widget.item.back.substring(0, visible),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _started = true);
                    await audio.speak(widget.item.back);
                  },
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(widget.step.type == ExerciseStepType.listen ? 'Escuchar' : 'Leer con guía'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _started ? widget.onContinue : null,
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordStepCard extends ConsumerStatefulWidget {
  const _RecordStepCard({
    required this.item,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final Color accent;
  final Future<void> Function(String path, int durationMs) onComplete;

  @override
  ConsumerState<_RecordStepCard> createState() => _RecordStepCardState();
}

class _RecordStepCardState extends ConsumerState<_RecordStepCard> {
  bool _recording = false;
  String? _path;
  DateTime? _startedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final audio = ref.read(audioPracticeServiceProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              _recording ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: widget.accent,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _recording ? 'Grabando lectura…' : 'Graba tu lectura en voz alta.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(widget.item.back, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_recording) {
                      final path = await audio.stopRecording();
                      final startedAt = _startedAt;
                      if (path != null && startedAt != null) {
                        final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
                        setState(() {
                          _recording = false;
                          _path = path;
                        });
                        await widget.onComplete(path, durationMs);
                      } else {
                        setState(() => _recording = false);
                      }
                    } else {
                      final path = await audio.startRecording(widget.item.id);
                      if (path != null) {
                        setState(() {
                          _recording = true;
                          _startedAt = DateTime.now();
                        });
                      }
                    }
                  },
                  icon: Icon(_recording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded),
                  label: Text(_recording ? 'Detener' : 'Grabar'),
                  style: FilledButton.styleFrom(backgroundColor: _recording ? AppColors.error : widget.accent),
                ),
              ),
            ],
          ),
          if (_path != null) ...[
            const SizedBox(height: 14),
            Text('Audio listo para reproducirse en el siguiente paso.', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _PlaybackStepCard extends ConsumerWidget {
  const _PlaybackStepCard({
    required this.path,
    required this.accent,
    required this.onComplete,
  });

  final String? path;
  final Color accent;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final audio = ref.read(audioPracticeServiceProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.queue_music_rounded, size: 44, color: accent),
          const SizedBox(height: 16),
          Text('Escucha tu grabación en un reproductor inferior.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: path == null
                      ? null
                      : () {
                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (sheetContext) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: () => audio.play(path!),
                                      icon: const Icon(Icons.play_arrow_rounded),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton.filledTonal(
                                      onPressed: audio.stopPlayback,
                                      icon: const Icon(Icons.stop_rounded),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Reproductor rápido de tu lectura.',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                  icon: const Icon(Icons.audio_file_rounded),
                  label: const Text('Abrir reproductor'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onComplete,
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
          if (path == null) ...[
            const SizedBox(height: 12),
            Text(
              'No hay audio guardado todavía. Puedes continuar con penalización leve o volver a grabar en otra sesión.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _FillOptionsStepCard extends ConsumerStatefulWidget {
  const _FillOptionsStepCard({
    required this.item,
    required this.deckItems,
    required this.step,
    required this.accent,
    required this.difficulty,
    required this.onComplete,
  });

  final Item item;
  final List<Item> deckItems;
  final ExerciseStep step;
  final Color accent;
  final MemorizationDifficulty difficulty;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_FillOptionsStepCard> createState() => _FillOptionsStepCardState();
}

class _FillOptionsStepCardState extends ConsumerState<_FillOptionsStepCard> {
  late FillOptionsChallenge _challenge;
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    final evaluator = ref.read(answerEvaluatorProvider);
    _challenge = evaluator.buildFillOptionsChallenge(
      item: widget.item,
      deckItems: widget.deckItems,
      level: widget.step.level!,
      difficulty: widget.difficulty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentIndex = _challenge.hiddenIndexes.firstWhere(
      (index) => !_answers.containsKey(index),
      orElse: () => -1,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _challenge.words.length; i++)
                Chip(
                  label: Text(
                    _challenge.hiddenIndexes.contains(i)
                        ? (_answers[i] ?? evaluator.maskWord(_challenge.words[i], widget.step.level!))
                        : _challenge.words[i],
                  ),
                  backgroundColor: _challenge.hiddenIndexes.contains(i)
                      ? widget.accent.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (currentIndex != -1) ...[
            Text('Selecciona la palabra correcta', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _GradualHintBox(
              expectedText: widget.item.back,
              accent: widget.accent,
              focusWords: [_challenge.words[currentIndex]],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (_challenge.optionsByIndex[currentIndex] ?? const <String>[])
                  .map((option) => ChoiceChip(
                        label: Text(option),
                        selected: _answers[currentIndex] == option,
                        onSelected: (_) => setState(() => _answers[currentIndex] = option),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _answers[currentIndex] == null ? null : () => setState(() {}),
              child: Text(
                _answers.length == _challenge.hiddenIndexes.length ? 'Listo para evaluar' : 'Siguiente palabra',
              ),
            ),
          ] else
            FilledButton.icon(
              onPressed: () async {
                final actual = _challenge.words.asMap().entries.map((entry) {
                  return _challenge.hiddenIndexes.contains(entry.key) ? _answers[entry.key] ?? '' : entry.value;
                }).join(' ');
                final result = evaluator.evaluate(
                  expected: widget.item.back,
                  actual: actual,
                  level: widget.step.level!,
                );
                await widget.onComplete(
                  score: result.score,
                  mistakes: result.mistakes,
                  payload: {'actual': actual},
                  evaluation: result,
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Evaluar completado'),
            ),
        ],
      ),
    );
  }
}

class _TypeFirstLetterStepCard extends ConsumerStatefulWidget {
  const _TypeFirstLetterStepCard({
    required this.item,
    required this.step,
    required this.accent,
    required this.difficulty,
    required this.onComplete,
  });

  final Item item;
  final ExerciseStep step;
  final Color accent;
  final MemorizationDifficulty difficulty;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_TypeFirstLetterStepCard> createState() => _TypeFirstLetterStepCardState();
}

class _TypeFirstLetterStepCardState extends ConsumerState<_TypeFirstLetterStepCard> {
  late FillOptionsChallenge _challenge;
  late Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final evaluator = ref.read(answerEvaluatorProvider);
    _challenge = evaluator.buildFillOptionsChallenge(
      item: widget.item,
      deckItems: [widget.item],
      level: widget.step.level!,
      difficulty: widget.difficulty,
    );
    _controllers = {
      for (final index in _challenge.hiddenIndexes) index: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escribe la primera letra de cada palabra oculta.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _GradualHintBox(
            expectedText: widget.item.back,
            accent: widget.accent,
            focusWords: [
              for (final index in _challenge.hiddenIndexes.take(2)) _challenge.words[index],
            ],
          ),
          const SizedBox(height: 16),
          ..._challenge.hiddenIndexes.map((index) {
            final word = _challenge.words[index];
            final masked = evaluator.maskWord(word, widget.step.level!);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: Text(masked)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _controllers[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              final reconstructed = _challenge.words.asMap().entries.map((entry) {
                if (!_challenge.hiddenIndexes.contains(entry.key)) return entry.value;
                final answer = _controllers[entry.key]!.text.trim();
                final expected = evaluator.firstLetterOf(entry.value);
                return answer.isEmpty ? '?' : (answer == expected ? entry.value : '$answer…');
              }).join(' ');
              final result = evaluator.evaluate(
                expected: widget.item.back,
                actual: reconstructed,
                level: widget.step.level!,
              );
              await widget.onComplete(
                score: result.score,
                mistakes: result.mistakes,
                payload: {'reconstructed': reconstructed},
                evaluation: result,
              );
            },
            icon: const Icon(Icons.keyboard_rounded),
            label: const Text('Validar letras'),
          ),
        ],
      ),
    );
  }
}

class _DetectErrorsStepCard extends ConsumerStatefulWidget {
  const _DetectErrorsStepCard({
    required this.item,
    required this.deckItems,
    required this.step,
    required this.accent,
    required this.onComplete,
  });

  final Item item;
  final List<Item> deckItems;
  final ExerciseStep step;
  final Color accent;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_DetectErrorsStepCard> createState() => _DetectErrorsStepCardState();
}

class _DetectErrorsStepCardState extends ConsumerState<_DetectErrorsStepCard> {
  late final ErrorDetectionChallenge _challenge;
  final Set<int> _selectedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    final evaluator = ref.read(answerEvaluatorProvider);
    _challenge = evaluator.buildErrorDetectionChallenge(
      item: widget.item,
      deckItems: widget.deckItems,
      level: widget.step.level!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detecta las palabras incorrectas.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Marca las palabras que no coinciden con el contenido original.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _challenge.displayWords.length; i++)
                FilterChip(
                  label: Text(_challenge.displayWords[i]),
                  selected: _selectedIndexes.contains(i),
                  selectedColor: AppColors.warning.withValues(alpha: 0.18),
                  onSelected: (_) {
                    setState(() {
                      if (_selectedIndexes.contains(i)) {
                        _selectedIndexes.remove(i);
                      } else {
                        _selectedIndexes.add(i);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              final expected = _challenge.alteredIndexes.toSet();
              final falseNegatives = expected.where((index) => !_selectedIndexes.contains(index)).length;
              final falsePositives = _selectedIndexes.where((index) => !expected.contains(index)).length;
              final mistakes = falseNegatives + falsePositives;
              final score = expected.isEmpty ? 1.0 : ((expected.length - mistakes) / expected.length).clamp(0.0, 1.0);
              await widget.onComplete(
                score: score,
                mistakes: mistakes,
                payload: {
                  'selectedIndexes': _selectedIndexes.toList(),
                  'alteredIndexes': _challenge.alteredIndexes,
                  'displayWords': _challenge.displayWords,
                },
              );
            },
            icon: const Icon(Icons.search_rounded),
            label: const Text('Validar errores'),
          ),
        ],
      ),
    );
  }
}

class _VoiceMatchStepCard extends ConsumerStatefulWidget {
  const _VoiceMatchStepCard({
    required this.item,
    required this.step,
    required this.accent,
    required this.latestTranscript,
    required this.onSetTranscript,
    required this.onComplete,
  });

  final Item item;
  final ExerciseStep step;
  final Color accent;
  final String? latestTranscript;
  final void Function(String transcript) onSetTranscript;
  final Future<void> Function({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) onComplete;

  @override
  ConsumerState<_VoiceMatchStepCard> createState() => _VoiceMatchStepCardState();
}

class _VoiceMatchStepCardState extends ConsumerState<_VoiceMatchStepCard> {
  late final TextEditingController _controller;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.latestTranscript);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = ref.read(answerEvaluatorProvider);
    final audio = ref.read(audioPracticeServiceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recita el contenido de memoria.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Puedes usar reconocimiento de voz o corregir el texto manualmente si el dispositivo falla.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          _GradualHintBox(
            expectedText: widget.item.back,
            accent: widget.accent,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'La transcripción aparecerá aquí…',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onSetTranscript,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_listening) {
                      await audio.stopListening();
                      setState(() => _listening = false);
                    } else {
                      final ok = await audio.startListening(
                        onResult: (transcript, isFinal) {
                          _controller.text = transcript;
                          widget.onSetTranscript(transcript);
                          if (isFinal && mounted) {
                            setState(() => _listening = false);
                          }
                        },
                      );
                      if (ok) {
                        setState(() => _listening = true);
                      }
                    }
                  },
                  icon: Icon(_listening ? Icons.stop_rounded : Icons.graphic_eq_rounded),
                  label: Text(_listening ? 'Detener escucha' : 'Usar micrófono'),
                  style: FilledButton.styleFrom(backgroundColor: _listening ? AppColors.error : widget.accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await audio.speak(widget.item.back);
                  },
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Oír referencia'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final result = evaluator.evaluate(
                expected: widget.item.back,
                actual: _controller.text,
                level: ExerciseLevel.level2,
              );
              await widget.onComplete(
                score: result.score,
                mistakes: result.mistakes,
                payload: {'transcript': _controller.text},
                transcript: _controller.text,
                evaluation: result,
              );
            },
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Comparar recitación'),
          ),
        ],
      ),
    );
  }
}

class _EvaluationBanner extends StatelessWidget {
  const _EvaluationBanner({required this.result, required this.accent});

  final AnswerEvaluationResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = result.isCorrect ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(result.isCorrect ? Icons.check_circle_rounded : Icons.info_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${result.feedback} Puntaje ${(result.score * 100).round()}% • Fallas ${result.mistakes}/${result.maxMistakes}',
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionChoiceCard extends StatelessWidget {
  const _VersionChoiceCard({
    required this.label,
    required this.content,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String content;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall?.copyWith(color: selected ? accent : null)),
            const SizedBox(height: 8),
            Text(content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _PracticeFinishedScreen extends ConsumerWidget {
  const _PracticeFinishedScreen({
    required this.completed,
    required this.deckName,
    required this.performanceSummaries,
    required this.completedItems,
    required this.objective,
    required this.cooperativePlayers,
    required this.cooperativeMode,
    required this.turnHandoffs,
    required this.rescueCount,
    this.coachFeedback,
    this.voiceFeedback,
    this.duelBestScore,
  });

  final int completed;
  final String deckName;
  final List<ExercisePerformanceSummary> performanceSummaries;
  final List<Item> completedItems;
  final PracticeObjective objective;
  final int cooperativePlayers;
  final CooperativeMode cooperativeMode;
  final int turnHandoffs;
  final int rescueCount;
  final String? coachFeedback;
  final String? voiceFeedback;
  final double? duelBestScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weakest = performanceSummaries.take(3).toList();
    final averageScore = performanceSummaries.isEmpty
        ? 0.0
        : performanceSummaries.fold<double>(0, (sum, summary) => sum + summary.averageScore) /
            performanceSummaries.length;
    final totalMistakes = performanceSummaries.fold<int>(0, (sum, summary) => sum + summary.totalMistakes);
    final primaryItemId = completedItems.length == 1 ? completedItems.first.id : null;
    final itemHistory = primaryItemId == null
        ? const <dynamic>[]
        : (ref.watch(recentItemConsolidationsProvider(primaryItemId)).valueOrNull ?? const []);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.success, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text('Sesión completada', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Terminaste $completed items de $deckName y el SRS ya fue actualizado.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Promedio',
                              value: '${(averageScore * 100).round()}%',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              label: 'Fallas',
                              value: '$totalMistakes',
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Consolidación', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  weakest.isEmpty
                      ? 'No hubo suficientes intentos para generar recomendaciones.'
                      : 'Tus puntos más débiles en esta sesión fueron: ${weakest.map((summary) => summary.type.label).join(', ')}.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (weakest.isNotEmpty)
                  ...weakest.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(summary.type.label, style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Promedio ${(summary.averageScore * 100).round()}% • Fallas ${summary.totalMistakes} • Intentos ${summary.attemptCount}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              summary.averageScore >= 0.75 ? Icons.trending_up_rounded : Icons.track_changes_rounded,
                              color: summary.averageScore >= 0.75 ? AppColors.info : AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    weakest.isEmpty
                        ? 'Siguiente sesión: repite una práctica rápida para generar más señal.'
                        : 'Siguiente sesión recomendada: empieza reforzando ${weakest.first.type.label.toLowerCase()} y luego vuelve a los ejercicios mixtos.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (cooperativePlayers > 1) ...[
                  const SizedBox(height: 20),
                  Text('Resumen cooperativo', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Grupo',
                                value: '$cooperativePlayers personas',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricTile(
                                label: 'Dinámica',
                                value: cooperativeMode.label,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Relevos',
                                value: '$turnHandoffs',
                                color: AppColors.indigo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricTile(
                                label: 'Rescates',
                                value: '$rescueCount',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          switch (cooperativeMode) {
                            CooperativeMode.solo =>
                              'Esta sesión fue individual, así que no hubo rotaciones de grupo.',
                            CooperativeMode.relay =>
                              'El grupo avanzó por relevo, pasando el contenido de una persona a otra sin competir.',
                            CooperativeMode.chain =>
                              'La cadena hizo que la memoria circulara paso por paso entre todos.',
                            CooperativeMode.rescue =>
                              rescueCount > 0
                                  ? 'Hubo $rescueCount rescates: el grupo se apoyó cuando alguien se trabó.'
                                  : 'No hizo falta rescatar: el grupo sostuvo bien la sesión completa.',
                          },
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
                if (coachFeedback != null) ...[
                  const SizedBox(height: 20),
                  Text('Coach IA', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                    ),
                    child: Text(coachFeedback!, style: theme.textTheme.bodyMedium),
                  ),
                ],
                if (voiceFeedback != null) ...[
                  const SizedBox(height: 20),
                  Text('Análisis de voz', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(voiceFeedback!, style: theme.textTheme.bodyMedium),
                ],
                if (objective == PracticeObjective.duel && duelBestScore != null) ...[
                  const SizedBox(height: 20),
                  Text('Resultado del duelo', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: averageScore >= duelBestScore!
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: averageScore >= duelBestScore!
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          averageScore >= duelBestScore! ? 'Nuevo récord personal' : 'Récord aún no superado',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actual ${(averageScore * 100).round()}% • Marca previa ${(duelBestScore! * 100).round()}% • Diferencia ${((averageScore - duelBestScore!) * 100).round()} pts',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    averageScore >= duelBestScore!
                        ? 'Ganaste contra tu mejor promedio anterior de ${(duelBestScore! * 100).round()}%.'
                        : 'Esta vez quedaste debajo de tu mejor promedio anterior de ${(duelBestScore! * 100).round()}%.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (primaryItemId != null) ...[
                  const SizedBox(height: 20),
                  Text('Historial reciente del item', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (itemHistory.isEmpty)
                    Text(
                      'Esta fue la primera consolidación guardada para este contenido.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    ...itemHistory.take(4).map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${record.difficulty.label} • ${(record.averageScore * 100).round()}% • Fallas ${record.totalMistakes}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            if (record.weakestStepType != null)
                              Text(
                                record.weakestStepType!.label,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver al deck'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
