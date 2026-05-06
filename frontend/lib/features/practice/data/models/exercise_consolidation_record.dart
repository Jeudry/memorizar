import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';

class ExerciseConsolidationRecord {
  const ExerciseConsolidationRecord({
    required this.id,
    required this.deckId,
    required this.itemId,
    required this.difficulty,
    required this.averageScore,
    required this.totalMistakes,
    required this.createdAt,
    this.weakestStepType,
    this.strongestStepType,
  });

  final int id;
  final String deckId;
  final String itemId;
  final MemorizationDifficulty difficulty;
  final double averageScore;
  final int totalMistakes;
  final DateTime createdAt;
  final ExerciseStepType? weakestStepType;
  final ExerciseStepType? strongestStepType;
}
