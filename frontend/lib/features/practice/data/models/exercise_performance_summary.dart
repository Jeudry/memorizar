import 'package:memorizar/features/practice/data/models/exercise_step.dart';

class ExercisePerformanceSummary {
  const ExercisePerformanceSummary({
    required this.type,
    required this.attemptCount,
    required this.averageScore,
    required this.totalMistakes,
  });

  final ExerciseStepType type;
  final int attemptCount;
  final double averageScore;
  final int totalMistakes;
}
