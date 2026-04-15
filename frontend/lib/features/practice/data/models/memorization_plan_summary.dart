import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';

class MemorizationPlanSummary {
  const MemorizationPlanSummary({
    required this.id,
    required this.deckId,
    required this.name,
    required this.difficulty,
    required this.itemCount,
    required this.createdAt,
  });

  final String id;
  final String deckId;
  final String name;
  final MemorizationDifficulty difficulty;
  final int itemCount;
  final DateTime createdAt;
}
