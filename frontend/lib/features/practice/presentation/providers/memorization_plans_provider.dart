import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/memorization_plan_summary.dart';

final memorizationPlansProvider =
    FutureProvider.family<List<MemorizationPlanSummary>, String>((ref, deckId) async {
  final db = ref.watch(databaseProvider);
  final plans = await db.getPlansForDeck(deckId);
  final summaries = <MemorizationPlanSummary>[];
  for (final plan in plans) {
    final items = await db.getPlanItems(plan.id);
    summaries.add(
      MemorizationPlanSummary(
        id: plan.id,
        deckId: plan.deckId,
        name: plan.name,
        difficulty: MemorizationDifficulty.fromStorage(plan.difficulty),
        itemCount: items.length,
        createdAt: plan.createdAt,
      ),
    );
  }
  return summaries;
});

class MemorizationPlansService {
  const MemorizationPlansService(this._db);

  final db.AppDatabase _db;

  Future<String> createQuickPlan({
    required String deckId,
    required MemorizationDifficulty difficulty,
    required List<Item> items,
  }) async {
    final id = 'plan_${deckId}_${DateTime.now().millisecondsSinceEpoch}';
    final planName = 'Plan ${difficulty.label}';

    await _db.createPlan(
      plan: db.MemorizationPlansCompanion.insert(
        id: id,
        deckId: deckId,
        name: planName,
        difficulty: difficulty.storageValue,
      ),
      items: [
        for (var i = 0; i < items.length; i++)
          db.MemorizationPlanItemsCompanion.insert(
            planId: id,
            itemId: items[i].id,
            position: i,
          ),
      ],
    );
    return id;
  }
}

final memorizationPlansServiceProvider = Provider<MemorizationPlansService>((ref) {
  final db = ref.watch(databaseProvider);
  return MemorizationPlansService(db);
});
