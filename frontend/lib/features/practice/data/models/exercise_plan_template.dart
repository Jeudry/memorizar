import 'dart:math';

import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';

class ExercisePlanTemplate {
  const ExercisePlanTemplate({
    required this.difficulty,
    required this.steps,
    this.fixedPrefixCount = 0,
    this.fixedSuffixCount = 0,
  });

  final MemorizationDifficulty difficulty;
  final List<ExerciseStep> steps;
  final int fixedPrefixCount;
  final int fixedSuffixCount;

  List<ExerciseStep> orderedStepsForSession([
    Random? random,
    Map<ExerciseStepType, double>? historicalAverageScores,
  ]) {
    if (steps.length <= fixedPrefixCount + fixedSuffixCount) {
      return [...steps];
    }

    final rng = random ?? Random();
    final prefix = steps.take(fixedPrefixCount).toList();
    final suffix = fixedSuffixCount == 0 ? <ExerciseStep>[] : steps.skip(steps.length - fixedSuffixCount).toList();
    final middle = steps.skip(fixedPrefixCount).take(steps.length - fixedPrefixCount - fixedSuffixCount).toList();
    final adaptedMiddle = _adaptMiddleSteps(middle, historicalAverageScores ?? const {});
    final orderedMiddle = _buildIntentionalMiddleOrder(adaptedMiddle, rng);

    return [...prefix, ...orderedMiddle, ...suffix];
  }

  List<ExerciseStep> _adaptMiddleSteps(
    List<ExerciseStep> middle,
    Map<ExerciseStepType, double> historicalAverageScores,
  ) {
    if (middle.isEmpty || historicalAverageScores.isEmpty) return [...middle];
    final adapted = [...middle];

    ExerciseStep? weakestStep;
    double weakestScore = 1.1;
    for (final step in middle) {
      final score = historicalAverageScores[step.type];
      if (score != null && score < 0.72 && score < weakestScore) {
        weakestScore = score;
        weakestStep = step;
      }
    }
    if (weakestStep != null) {
      adapted.add(weakestStep);
    }

    final countsByType = <ExerciseStepType, int>{};
    for (final step in adapted) {
      countsByType.update(step.type, (count) => count + 1, ifAbsent: () => 1);
    }

    ExerciseStepType? strongestType;
    double strongestScore = -1;
    for (final entry in countsByType.entries) {
      final score = historicalAverageScores[entry.key];
      if (entry.value > 1 && score != null && score > 0.92 && score > strongestScore) {
        strongestScore = score;
        strongestType = entry.key;
      }
    }
    if (strongestType != null) {
      final index = adapted.lastIndexWhere((step) => step.type == strongestType);
      if (index != -1) {
        adapted.removeAt(index);
      }
    }

    return adapted;
  }

  List<ExerciseStep> _buildIntentionalMiddleOrder(List<ExerciseStep> middle, Random rng) {
    if (middle.length < 2) return [...middle];
    final pool = [...middle]..shuffle(rng);
    final ordered = <ExerciseStep>[];

    while (pool.isNotEmpty) {
      final previousType = ordered.isEmpty ? null : ordered.last.type;
      var pickIndex = pool.indexWhere((step) => step.type != previousType);
      pickIndex = pickIndex == -1 ? 0 : pickIndex;
      ordered.add(pool.removeAt(pickIndex));
    }

    return ordered;
  }
}
