import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/practice/data/models/memorization_journey.dart';

final memorizationJourneysProvider =
    FutureProvider.family<List<MemorizationJourney>, String>((ref, deckId) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.getJourneysForDeck(deckId);
  return rows
      .map(
        (row) => MemorizationJourney(
          id: row.id,
          deckId: row.deckId,
          title: row.title,
          targetDays: row.targetDays,
          itemsPerDay: row.itemsPerDay,
          targetItemCount: row.targetItemCount,
          objective: row.objective,
          createdAt: row.createdAt,
        ),
      )
      .toList();
});

final memorizationJourneysControllerProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return _MemorizationJourneysController(database, ref);
});

class _MemorizationJourneysController {
  const _MemorizationJourneysController(this._database, this._ref);

  final db.AppDatabase _database;
  final Ref _ref;

  Future<void> createJourney({
    required String deckId,
    required String title,
    required int targetDays,
    required int itemsPerDay,
    required int targetItemCount,
    required String objective,
  }) async {
    final id = 'journey_${DateTime.now().microsecondsSinceEpoch}';
    await _database.createJourney(
      db.MemorizationJourneysCompanion.insert(
        id: id,
        deckId: deckId,
        title: title,
        targetDays: targetDays,
        itemsPerDay: itemsPerDay,
        targetItemCount: targetItemCount,
        objective: objective,
      ),
    );
    _ref.invalidate(memorizationJourneysProvider(deckId));
  }
}
