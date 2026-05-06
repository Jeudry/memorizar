import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/practice/data/models/memorization_goal.dart';

final memorizationGoalsProvider =
    FutureProvider.family<List<MemorizationGoal>, String>((ref, deckId) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.getGoalsForDeck(deckId);
  return rows
      .map(
        (row) => MemorizationGoal(
          id: row.id,
          deckId: row.deckId,
          title: row.title,
          objective: row.objective,
          targetItems: row.targetItems,
          targetDate: row.targetDate,
          status: row.status,
          createdAt: row.createdAt,
        ),
      )
      .toList();
});

final memorizationGoalsControllerProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return _MemorizationGoalsController(database, ref);
});

class _MemorizationGoalsController {
  const _MemorizationGoalsController(this._database, this._ref);

  final db.AppDatabase _database;
  final Ref _ref;

  Future<void> createGoal({
    required String deckId,
    required String title,
    required String objective,
    required int targetItems,
    DateTime? targetDate,
  }) async {
    final id = 'goal_${DateTime.now().microsecondsSinceEpoch}';
    await _database.createGoal(
      db.MemorizationGoalsCompanion.insert(
        id: id,
        deckId: deckId,
        title: title,
        objective: objective,
        targetItems: Value(targetItems),
        targetDate: Value(targetDate),
      ),
    );
    _ref.invalidate(memorizationGoalsProvider(deckId));
  }
}
