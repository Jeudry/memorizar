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
    adaptedMiddle.shuffle(rng);

    return [...prefix, ...adaptedMiddle, ...suffix];
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
}
