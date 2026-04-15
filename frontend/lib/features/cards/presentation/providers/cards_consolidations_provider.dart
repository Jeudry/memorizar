import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/cards/data/models/cards_consolidation_record.dart';

final recentCardsDeckConsolidationsProvider =
    FutureProvider.family<List<CardsConsolidationRecord>, String>((ref, deckId) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.getRecentCardsConsolidationsForDeck(deckId);
  return rows
      .map(
        (row) => CardsConsolidationRecord(
          id: row.id,
          deckId: row.deckId,
          averageScore: row.averageScore,
          totalMistakes: row.totalMistakes,
          createdAt: row.createdAt,
          weakestExerciseType: row.weakestExerciseType,
          strongestExerciseType: row.strongestExerciseType,
        ),
      )
      .toList();
});
