import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';

class ExerciseSessionArgs {
  const ExerciseSessionArgs({
    required this.deckId,
    required this.difficulty,
    this.objective = PracticeObjective.deep,
    this.planId,
    this.itemId,
    this.weakOnly = false,
    this.cooperativePlayers = 1,
    this.cooperativeMode = CooperativeMode.solo,
  });

  final String deckId;
  final MemorizationDifficulty difficulty;
  final PracticeObjective objective;
  final String? planId;
  final String? itemId;
  final bool weakOnly;
  final int cooperativePlayers;
  final CooperativeMode cooperativeMode;

  @override
  bool operator ==(Object other) {
    return other is ExerciseSessionArgs &&
        other.deckId == deckId &&
        other.difficulty == difficulty &&
        other.objective == objective &&
        other.planId == planId &&
        other.itemId == itemId &&
        other.weakOnly == weakOnly &&
        other.cooperativePlayers == cooperativePlayers &&
        other.cooperativeMode == cooperativeMode;
  }

  @override
  int get hashCode =>
      Object.hash(deckId, difficulty, objective, planId, itemId, weakOnly, cooperativePlayers, cooperativeMode);
}
