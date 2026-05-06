import 'dart:math';

import 'package:memorizar/features/practice/data/models/exercise_level.dart';
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
    final randomizedMiddle = _randomizeByDifficulty(adaptedMiddle, rng);

    return [...prefix, ...randomizedMiddle, ...suffix];
  }

  List<ExerciseStep> _randomizeByDifficulty(List<ExerciseStep> middle, Random rng) {
    if (middle.isEmpty) return [];

    // Separate reconstructBlocks (level 2) - always include it as the first middle step
    final reconstructBlock = middle.where((s) => s.type == ExerciseStepType.reconstructBlocks).toList();
    final otherSteps = middle.where((s) => s.type != ExerciseStepType.reconstructBlocks).toList();

    // Group by level
    final level1 = otherSteps.where((s) => s.level == ExerciseLevel.level1).toList();
    final level2 = otherSteps.where((s) => s.level == ExerciseLevel.level2).toList();
    final level3 = otherSteps.where((s) => s.level == ExerciseLevel.level3).toList();
    final noLevel = otherSteps.where((s) => s.level == null).toList();

    // Randomly select subset from each level (not all exercises every time)
    // Pick 50-100% of exercises from each level randomly
    final selectedLevel1 = _selectRandomSubset(level1, rng, minRatio: 0.6);
    final selectedLevel2 = _selectRandomSubset(level2, rng, minRatio: 0.5);
    final selectedLevel3 = _selectRandomSubset(level3, rng, minRatio: 0.7);

    // Shuffle within each level
    selectedLevel1.shuffle(rng);
    selectedLevel2.shuffle(rng);
    selectedLevel3.shuffle(rng);
    noLevel.shuffle(rng);

    // Order: reconstructBlocks (level 2, always first) → level1 → level2 → noLevel → level3
    return [
      ...reconstructBlock,
      ...selectedLevel1,
      ...selectedLevel2,
      ...noLevel,
      ...selectedLevel3,
    ];
  }

  List<ExerciseStep> _selectRandomSubset(List<ExerciseStep> steps, Random rng, {required double minRatio}) {
    if (steps.length <= 1) return [...steps];
    final minCount = (steps.length * minRatio).ceil().clamp(1, steps.length);
    final maxCount = steps.length;
    final targetCount = minCount + rng.nextInt(maxCount - minCount + 1);
    final shuffled = [...steps]..shuffle(rng);
    return shuffled.take(targetCount).toList();
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
