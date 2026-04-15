import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/practice/data/models/exercise_consolidation_record.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';

final recentDeckConsolidationsProvider =
    FutureProvider.family<List<ExerciseConsolidationRecord>, String>((ref, deckId) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.getRecentConsolidationsForDeck(deckId);
  return rows.map(_mapConsolidation).toList();
});

final recentItemConsolidationsProvider =
    FutureProvider.family<List<ExerciseConsolidationRecord>, String>((ref, itemId) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.getRecentConsolidationsForItem(itemId);
  return rows.map(_mapConsolidation).toList();
});

ExerciseConsolidationRecord _mapConsolidation(db.ExerciseConsolidation row) {
  ExerciseStepType? parseType(String? storageValue) {
    if (storageValue == null) return null;
    for (final value in ExerciseStepType.values) {
      if (value.storageValue == storageValue) return value;
    }
    return null;
  }

  return ExerciseConsolidationRecord(
    id: row.id,
    deckId: row.deckId,
    itemId: row.itemId,
    difficulty: MemorizationDifficulty.fromStorage(row.difficulty),
    averageScore: row.averageScore,
    totalMistakes: row.totalMistakes,
    createdAt: row.createdAt,
    weakestStepType: parseType(row.weakestStepType),
    strongestStepType: parseType(row.strongestStepType),
  );
}
