import 'dart:math';
import 'dart:convert';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/data/models/answer_evaluation_result.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/exercise_performance_summary.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_args.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_state.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_templates_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/practice_services_provider.dart';
import 'package:memorizar/features/review/data/models/review_rating.dart';

final exerciseSessionProvider = StateNotifierProvider.autoDispose
    .family<ExerciseSessionNotifier, ExerciseSessionState, ExerciseSessionArgs>(
  (ref, args) => ExerciseSessionNotifier(ref, args),
);

class ExerciseSessionNotifier extends StateNotifier<ExerciseSessionState> {
  ExerciseSessionNotifier(this._ref, this._args)
      : super(ExerciseSessionState.initial(
          _args.difficulty,
          objective: _args.objective,
          cooperativePlayers: _args.cooperativePlayers,
          cooperativeMode: _args.cooperativePlayers <= 1 ? CooperativeMode.solo : _args.cooperativeMode,
        )) {
    _init();
  }

  final Ref _ref;
  final ExerciseSessionArgs _args;
  final Map<String, List<double>> _scoresByItem = <String, List<double>>{};
  final Map<ExerciseStepType, _StepPerformanceAccumulator> _performanceByStep =
      <ExerciseStepType, _StepPerformanceAccumulator>{};
  final Map<String, Map<ExerciseStepType, _StepPerformanceAccumulator>> _performanceByItemAndStep =
      <String, Map<ExerciseStepType, _StepPerformanceAccumulator>>{};

  Future<void> _init() async {
    final database = _ref.read(databaseProvider);
    final templates = _ref.read(exerciseTemplatesProvider);
    final template = templates[_args.difficulty]!;

    List<db.Item> rows;
    String? planName;
    if (_args.planId != null) {
      rows = await database.getItemsForPlan(_args.planId!);
      final plan = await (database.select(database.memorizationPlans)..where((p) => p.id.equals(_args.planId!)))
          .getSingleOrNull();
      planName = plan?.name;
    } else if (_args.itemId != null) {
      final row = await (database.select(database.items)..where((item) => item.id.equals(_args.itemId!)))
          .getSingleOrNull();
      rows = row == null ? const [] : [row];
    } else {
      rows = await database.getDueItems(_args.deckId);
      if (rows.isEmpty) {
        rows = await database.getItemsForDeck(_args.deckId);
      }
    }

    final queue = rows.map(_dbItemToItem).toList();
    final recentAttempts = await database.getExerciseAttemptsForItems(queue.map((item) => item.id).toList());
    final recentErrorBank = await database.getRecentErrorBankEntriesForItems(queue.map((item) => item.id).toList());
    final historicalAverageScores = _buildHistoricalAverageScores(recentAttempts);
    final errorStepWeights = _buildErrorStepWeights(recentErrorBank);
    final baseSteps = template.orderedStepsForSession(
      Random(DateTime.now().microsecondsSinceEpoch),
      historicalAverageScores,
    );
    final sessionSteps = _resolveSessionSteps(baseSteps, historicalAverageScores, errorStepWeights);
    final recentConsolidations = await database.getRecentConsolidationsForDeck(_args.deckId, limit: 24);
    final duelBestScore = recentConsolidations.isEmpty
        ? null
        : recentConsolidations.map((entry) => entry.averageScore).reduce(max);
    state = state.copyWith(
      queue: queue,
      steps: sessionSteps,
      deckId: _args.deckId,
      planId: _args.planId,
      planName: planName,
      objective: _args.objective,
      cooperativePlayers: _args.cooperativePlayers,
      cooperativeMode: _args.cooperativePlayers <= 1 ? CooperativeMode.solo : _args.cooperativeMode,
      duelBestScore: duelBestScore,
      isLoading: false,
      isFinished: queue.isEmpty,
    );
  }

  Future<void> completeCurrentStep({
    required double score,
    required int mistakes,
    Map<String, Object?>? payload,
    AnswerEvaluationResult? evaluation,
    String? transcript,
    String? latestAudioPath,
  }) async {
    final item = state.currentItem;
    final step = state.currentStep;
    if (item == null || step == null) return;

    final database = _ref.read(databaseProvider);
    await database.logExerciseAttempt(
      db.ExerciseAttemptsCompanion.insert(
        itemId: item.id,
        stepType: step.type.storageValue,
        level: Value(step.level?.name),
        difficulty: _args.difficulty.storageValue,
        score: score,
        mistakes: Value(mistakes),
        payloadJson: Value(payload == null ? null : jsonEncode(payload)),
      ),
    );
    await _logErrorBankEntries(
      item: item,
      step: step,
      evaluation: evaluation,
      score: score,
      mistakes: mistakes,
    );

    _scoresByItem.putIfAbsent(item.id, () => <double>[]).add(score);
    final accumulator = _performanceByStep.putIfAbsent(step.type, () => _StepPerformanceAccumulator());
    accumulator.attemptCount += 1;
    accumulator.totalScore += score;
    accumulator.totalMistakes += mistakes;
    final itemMap = _performanceByItemAndStep.putIfAbsent(item.id, () => <ExerciseStepType, _StepPerformanceAccumulator>{});
    final itemAccumulator = itemMap.putIfAbsent(step.type, () => _StepPerformanceAccumulator());
    itemAccumulator.attemptCount += 1;
    itemAccumulator.totalScore += score;
    itemAccumulator.totalMistakes += mistakes;

    final isLastStep = state.currentStepIndex >= state.steps.length - 1;
    if (latestAudioPath != null) {
      state = state.copyWith(latestAudioPath: latestAudioPath);
    }
    if (transcript != null) {
      state = state.copyWith(latestTranscript: transcript);
    }

    final shouldRescue = state.cooperativePlayers > 1 &&
        state.cooperativeMode == CooperativeMode.rescue &&
        !state.rescuePending &&
        score < 0.7;

    if (shouldRescue) {
      state = state.copyWith(
        currentTurnIndex: _nextTurnIndex(state.currentTurnIndex),
        rescuePending: true,
        turnHandoffs: state.turnHandoffs + 1,
        rescueCount: state.rescueCount + 1,
        lastEvaluation: evaluation,
        performanceSummaries: _buildPerformanceSummaries(),
      );
      return;
    }

    if (isLastStep) {
      await _finishCurrentItem(item);
    } else {
      final skipBoost = _shouldSkipAhead(score, step.type);
      final nextStepIndex = (state.currentStepIndex + 1 + skipBoost).clamp(0, state.steps.length - 1);
      final updatedTurnIndex = _turnIndexAfterStepAdvance(
        currentTurnIndex: state.currentTurnIndex,
        stepAdvanced: true,
      );
      state = state.copyWith(
        currentStepIndex: nextStepIndex,
        currentTurnIndex: updatedTurnIndex,
        rescuePending: false,
        turnHandoffs: state.turnHandoffs +
            ((state.cooperativePlayers > 1 && updatedTurnIndex != state.currentTurnIndex) ? 1 : 0),
        lastEvaluation: evaluation,
        performanceSummaries: _buildPerformanceSummaries(),
      );
    }
  }

  Future<void> saveAudioClip(String path, {int durationMs = 0}) async {
    final item = state.currentItem;
    if (item == null) return;
    final database = _ref.read(databaseProvider);
    await database.saveAudioClip(
      db.AudioClipsCompanion.insert(
        itemId: item.id,
        localPath: path,
        durationMs: Value(durationMs),
      ),
    );
    state = state.copyWith(latestAudioPath: path);
  }

  void setTranscript(String transcript) {
    state = state.copyWith(latestTranscript: transcript);
  }

  void clearFeedback() {
    state = state.copyWith(clearEvaluation: true);
  }

  Future<void> _finishCurrentItem(Item item) async {
    final itemScores = _scoresByItem[item.id] ?? const [0.0];
    final total = itemScores.fold<double>(0, (sum, score) => sum + score);
    final average = itemScores.isEmpty ? 0.0 : total / itemScores.length;
    final rating = _scoreToRating(average);
    final updated = _applySm2(item, rating);
    final itemSummaries = _buildItemPerformanceSummaries(item.id);

    final database = _ref.read(databaseProvider);
    await database.updateItemSrs(
      item.id,
      easeFactor: updated.easeFactor,
      interval: updated.interval,
      repetitions: updated.repetitions,
      nextReviewAt: updated.nextReviewAt!,
    );
    await database.logReview(
      db.ReviewLogsCompanion.insert(
        itemId: item.id,
        deckId: item.deckId,
        rating: rating.name,
        intervalBefore: item.interval,
        intervalAfter: updated.interval,
      ),
    );
    await database.saveExerciseConsolidation(
      db.ExerciseConsolidationsCompanion.insert(
        deckId: item.deckId,
        itemId: item.id,
        difficulty: _args.difficulty.storageValue,
        averageScore: average,
        totalMistakes: Value(itemSummaries.fold<int>(0, (sum, summary) => sum + summary.totalMistakes)),
        weakestStepType: Value(itemSummaries.isEmpty ? null : itemSummaries.first.type.storageValue),
        strongestStepType: Value(itemSummaries.isEmpty ? null : itemSummaries.last.type.storageValue),
      ),
    );

    final completed = [...state.completedItems, updated];
    final nextItemIndex = state.currentItemIndex + 1;
    final finished = nextItemIndex >= state.queue.length;
    final coach = _ref.read(practiceCoachProvider);
    final updatedTurnIndex = finished ? state.currentTurnIndex : _turnIndexAfterItemAdvance(state.currentTurnIndex);
    state = state.copyWith(
      completedItems: completed,
      currentItemIndex: finished ? state.currentItemIndex : nextItemIndex,
      currentStepIndex: 0,
      currentTurnIndex: updatedTurnIndex,
      rescuePending: false,
      turnHandoffs: state.turnHandoffs +
          ((state.cooperativePlayers > 1 && updatedTurnIndex != state.currentTurnIndex) ? 1 : 0),
      isFinished: finished,
      lastEvaluation: null,
      performanceSummaries: _buildPerformanceSummaries(),
      coachFeedback: coach.buildCoachFeedback(
        summaries: _buildPerformanceSummaries(),
        objective: state.objective,
      ),
      voiceFeedback: coach.buildVoiceFeedback(
        transcript: state.latestTranscript,
        score: average,
      ),
      clearAudioPath: true,
      clearTranscript: true,
    );
    if (finished && state.cooperativePlayers > 1) {
      await _ref.read(cooperativeFollowUpProvider.notifier).saveFromSession(
            deckId: item.deckId,
            mode: state.cooperativeMode,
            averageScore: averageScoreForSession(state.performanceSummaries),
            rescueCount: state.rescueCount,
          );
    }
  }

  double averageScoreForSession(List<ExercisePerformanceSummary> summaries) {
    if (summaries.isEmpty) return 0;
    return summaries.fold<double>(0, (sum, summary) => sum + summary.averageScore) / summaries.length;
  }

  int _nextTurnIndex(int currentTurnIndex) {
    if (state.cooperativePlayers <= 1) return 0;
    return (currentTurnIndex + 1) % state.cooperativePlayers;
  }

  int _turnIndexAfterStepAdvance({
    required int currentTurnIndex,
    required bool stepAdvanced,
  }) {
    if (!stepAdvanced || state.cooperativePlayers <= 1) return currentTurnIndex;
    return switch (state.cooperativeMode) {
      CooperativeMode.solo => 0,
      CooperativeMode.relay => currentTurnIndex,
      CooperativeMode.chain => _nextTurnIndex(currentTurnIndex),
      CooperativeMode.rescue => _nextTurnIndex(currentTurnIndex),
    };
  }

  int _turnIndexAfterItemAdvance(int currentTurnIndex) {
    if (state.cooperativePlayers <= 1) return 0;
    return switch (state.cooperativeMode) {
      CooperativeMode.solo => 0,
      CooperativeMode.relay => _nextTurnIndex(currentTurnIndex),
      CooperativeMode.chain => _nextTurnIndex(currentTurnIndex),
      CooperativeMode.rescue => _nextTurnIndex(currentTurnIndex),
    };
  }

  List<ExerciseStep> _resolveSessionSteps(
    List<ExerciseStep> baseSteps,
    Map<ExerciseStepType, double> historicalAverageScores,
    Map<ExerciseStepType, int> errorStepWeights,
  ) {
    var steps = [...baseSteps];

    if (_args.weakOnly && historicalAverageScores.isNotEmpty) {
      final weakest = historicalAverageScores.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final selectedTypes = weakest.take(4).map((entry) => entry.key).toSet();
      steps = steps.where((step) => selectedTypes.contains(step.type) || _alwaysKeepTypes.contains(step.type)).toList();
    }

    if (errorStepWeights.isNotEmpty && _args.objective != PracticeObjective.totalExam) {
      final weakTypes = errorStepWeights.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in weakTypes.take(2)) {
        final existing = steps.where((step) => step.type == entry.key).toList();
        if (existing.isNotEmpty && !_alwaysKeepTypes.contains(entry.key)) {
          steps.insert(0, existing.first);
        }
      }
    }

    switch (_args.objective) {
      case PracticeObjective.quick:
        steps = steps.where((step) => _quickTypes.contains(step.type) || _alwaysKeepTypes.contains(step.type)).toList();
      case PracticeObjective.deep:
        steps = [
          const ExerciseStep(
            type: ExerciseStepType.thematicBlocks,
            instruction: 'Ubica el contenido dentro de un bloque o tema general.',
          ),
          ...steps,
          const ExerciseStep(
            type: ExerciseStepType.reverseReference,
            instruction: 'Recuerda la referencia correcta del contenido.',
          ),
          const ExerciseStep(
            type: ExerciseStepType.coachReview,
            instruction: 'Cierra con feedback inteligente para la siguiente ronda.',
          ),
        ];
      case PracticeObjective.duel:
        steps = [
          ...steps.where((step) => _quickTypes.contains(step.type) || _alwaysKeepTypes.contains(step.type)),
          const ExerciseStep(
            type: ExerciseStepType.totalExam,
            instruction: 'Haz un cierre contra tu mejor marca reciente.',
          ),
          const ExerciseStep(
            type: ExerciseStepType.coachReview,
            instruction: 'Compara el intento actual con tu historial.',
          ),
        ];
      case PracticeObjective.totalExam:
        steps = const [
          ExerciseStep(
            type: ExerciseStepType.reverseReference,
            instruction: 'Recuerda la referencia exacta desde el contenido.',
          ),
          ExerciseStep(
            type: ExerciseStepType.thematicBlocks,
            instruction: 'Identifica el bloque o tema general del contenido.',
          ),
          ExerciseStep(
            type: ExerciseStepType.totalExam,
            instruction: 'Resuelve el examen total casi sin ayudas.',
          ),
          ExerciseStep(
            type: ExerciseStepType.reciteFromMemoryVoice,
            instruction: 'Recita todo el contenido por voz para cerrar.',
          ),
          ExerciseStep(
            type: ExerciseStepType.coachReview,
            instruction: 'Recibe el feedback final y la recomendación siguiente.',
          ),
        ];
      case PracticeObjective.master:
        steps = const [
          ExerciseStep(
            type: ExerciseStepType.segmentedRecall,
            instruction: 'Demuestra dominio por tramos sin calentamiento largo.',
          ),
          ExerciseStep(
            type: ExerciseStepType.randomStart,
            instruction: 'Arranca desde un punto aleatorio del contenido.',
          ),
          ExerciseStep(
            type: ExerciseStepType.cutIn,
            instruction: 'Continúa el contenido justo después de un corte.',
          ),
          ExerciseStep(
            type: ExerciseStepType.reverseReference,
            instruction: 'Recuerda la referencia exacta sin pistas.',
          ),
          ExerciseStep(
            type: ExerciseStepType.thematicBlocks,
            instruction: 'Ubica el contenido dentro de su bloque conceptual.',
          ),
          ExerciseStep(
            type: ExerciseStepType.pressureRecall,
            instruction: 'Resuelve bajo presión con poco margen de pausa.',
          ),
          ExerciseStep(
            type: ExerciseStepType.totalExam,
            instruction: 'Cierra con un examen total sin ayudas.',
          ),
          ExerciseStep(
            type: ExerciseStepType.coachReview,
            instruction: 'Recibe feedback final del modo maestro.',
          ),
        ];
    }

    return steps;
  }

  Future<void> _logErrorBankEntries({
    required Item item,
    required ExerciseStep step,
    required AnswerEvaluationResult? evaluation,
    required double score,
    required int mistakes,
  }) async {
    if ((evaluation == null || evaluation.missingWords.isEmpty) && mistakes == 0 && score >= 0.7) {
      return;
    }
    final database = _ref.read(databaseProvider);
    final tokens = evaluation == null || evaluation.missingWords.isEmpty
        ? const <String?>[null]
        : evaluation.missingWords.take(4).cast<String?>();
    await database.logErrorBankEntries([
      for (final token in tokens)
        db.ErrorBankEntriesCompanion.insert(
          itemId: item.id,
          deckId: item.deckId,
          stepType: step.type.storageValue,
          token: Value(token),
          errorKind: evaluation == null ? 'generic_miss' : 'missing_word',
          occurrences: const Value(1),
        ),
    ]);
  }

  int _shouldSkipAhead(double score, ExerciseStepType completedType) {
    if (score < 0.94) return 0;
    if (_args.objective == PracticeObjective.master) return 1;
    if ({
      ExerciseStepType.listen,
      ExerciseStepType.readAlong,
      ExerciseStepType.segmentedRecall,
      ExerciseStepType.fillOptions,
      ExerciseStepType.typeFirstLetter,
    }.contains(completedType)) {
      return 1;
    }
    return 0;
  }

  List<ExercisePerformanceSummary> _buildPerformanceSummaries() {
    final summaries = _performanceByStep.entries
        .map(
          (entry) => ExercisePerformanceSummary(
            type: entry.key,
            attemptCount: entry.value.attemptCount,
            averageScore: entry.value.attemptCount == 0 ? 0 : entry.value.totalScore / entry.value.attemptCount,
            totalMistakes: entry.value.totalMistakes,
          ),
        )
        .toList()
      ..sort((a, b) {
        final scoreCompare = a.averageScore.compareTo(b.averageScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.totalMistakes.compareTo(a.totalMistakes);
      });
    return summaries;
  }

  List<ExercisePerformanceSummary> _buildItemPerformanceSummaries(String itemId) {
    final itemMap = _performanceByItemAndStep[itemId] ?? const <ExerciseStepType, _StepPerformanceAccumulator>{};
    final summaries = itemMap.entries
        .map(
          (entry) => ExercisePerformanceSummary(
            type: entry.key,
            attemptCount: entry.value.attemptCount,
            averageScore: entry.value.attemptCount == 0 ? 0 : entry.value.totalScore / entry.value.attemptCount,
            totalMistakes: entry.value.totalMistakes,
          ),
        )
        .toList()
      ..sort((a, b) {
        final scoreCompare = a.averageScore.compareTo(b.averageScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.totalMistakes.compareTo(a.totalMistakes);
      });
    return summaries;
  }

  Map<ExerciseStepType, double> _buildHistoricalAverageScores(List<db.ExerciseAttempt> attempts) {
    final totals = <ExerciseStepType, _StepPerformanceAccumulator>{};
    for (final attempt in attempts) {
      final type = ExerciseStepType.values.firstWhere(
        (value) => value.storageValue == attempt.stepType,
        orElse: () => ExerciseStepType.fillOptions,
      );
      final accumulator = totals.putIfAbsent(type, () => _StepPerformanceAccumulator());
      accumulator.attemptCount += 1;
      accumulator.totalScore += attempt.score;
      accumulator.totalMistakes += attempt.mistakes;
    }

    return {
      for (final entry in totals.entries)
        if (entry.value.attemptCount > 0) entry.key: entry.value.totalScore / entry.value.attemptCount,
    };
  }

  Map<ExerciseStepType, int> _buildErrorStepWeights(List<db.ErrorBankEntry> entries) {
    final weights = <ExerciseStepType, int>{};
    for (final entry in entries) {
      final type = ExerciseStepType.values.firstWhere(
        (value) => value.storageValue == entry.stepType,
        orElse: () => ExerciseStepType.fillOptions,
      );
      weights[type] = (weights[type] ?? 0) + entry.occurrences;
    }
    return weights;
  }

  ReviewRating _scoreToRating(double score) {
    if (score >= 0.9) return ReviewRating.easy;
    if (score >= 0.75) return ReviewRating.good;
    if (score >= 0.5) return ReviewRating.hard;
    return ReviewRating.again;
  }

  Item _applySm2(Item item, ReviewRating rating) {
    final q = rating.quality;
    var easeFactor = item.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    late final int interval;
    late final int repetitions;

    if (q < 3) {
      interval = 1;
      repetitions = 0;
    } else {
      repetitions = item.repetitions + 1;
      interval = switch (repetitions) {
        1 => 1,
        2 => 6,
        _ => (item.interval * easeFactor).round(),
      };
    }

    return item.copyWith(
      easeFactor: easeFactor,
      interval: interval,
      repetitions: repetitions,
      nextReviewAt: DateTime.now().add(Duration(days: interval)),
      lastReviewedAt: DateTime.now(),
    );
  }

  Item _dbItemToItem(db.Item row) => Item(
        id: row.id,
        deckId: row.deckId,
        front: row.front,
        back: row.back,
        easeFactor: row.easeFactor,
        interval: row.interval,
        repetitions: row.repetitions,
        nextReviewAt: row.nextReviewAt,
        lastReviewedAt: row.lastReviewedAt,
        book: row.book,
        chapter: row.chapter,
        verse: row.verse,
      );
}

const Set<ExerciseStepType> _quickTypes = {
  ExerciseStepType.listen,
  ExerciseStepType.readAlong,
  ExerciseStepType.reconstructBlocks,
  ExerciseStepType.segmentedRecall,
  ExerciseStepType.fillOptions,
  ExerciseStepType.typeFirstLetter,
  ExerciseStepType.reverseReference,
  ExerciseStepType.randomStart,
  ExerciseStepType.cutIn,
};

const Set<ExerciseStepType> _alwaysKeepTypes = {
  ExerciseStepType.recordReading,
  ExerciseStepType.playRecording,
  ExerciseStepType.reciteFromMemoryVoice,
};

class _StepPerformanceAccumulator {
  int attemptCount = 0;
  double totalScore = 0;
  int totalMistakes = 0;
}
