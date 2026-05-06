import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/decks/data/models/item_mastery_record.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_consolidations_provider.dart';

final itemMasteryMapProvider =
    FutureProvider.family<List<ItemMasteryRecord>, String>((ref, deckId) async {
  final items = await ref.watch(itemsForDeckProvider(deckId).future);
  final consolidations = await ref.watch(recentDeckConsolidationsProvider(deckId).future);

  return items.map((item) {
    final matching = consolidations.where((entry) => entry.itemId == item.id).toList();
    final score = matching.isEmpty
        ? 0.0
        : matching.map((entry) => entry.averageScore).reduce((a, b) => a + b) / matching.length;
    final label = switch (score) {
      >= 0.82 => 'Fuerte',
      >= 0.6 => 'En progreso',
      > 0 => 'Débil',
      _ => 'Sin señal',
    };
    return ItemMasteryRecord(
      itemId: item.id,
      front: item.front,
      score: score,
      label: label,
    );
  }).toList();
});
