class CardsConsolidationRecord {
  const CardsConsolidationRecord({
    required this.id,
    required this.deckId,
    required this.averageScore,
    required this.totalMistakes,
    required this.createdAt,
    this.weakestExerciseType,
    this.strongestExerciseType,
  });

  final int id;
  final String deckId;
  final double averageScore;
  final int totalMistakes;
  final DateTime createdAt;
  final String? weakestExerciseType;
  final String? strongestExerciseType;
}
