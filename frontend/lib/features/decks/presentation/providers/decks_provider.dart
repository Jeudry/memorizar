import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/decks/data/mock_data.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/models/item.dart';

final decksProvider = Provider<List<Deck>>((ref) => mockDecks);

final deckByIdProvider = Provider.family<Deck?, String>((ref, id) {
  final decks = ref.watch(decksProvider);
  try {
    return decks.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
});

final itemsForDeckProvider = Provider.family<List<Item>, String>((ref, deckId) {
  return allMockItems[deckId] ?? [];
});

final dueItemsProvider = Provider.family<List<Item>, String>((ref, deckId) {
  final items = ref.watch(itemsForDeckProvider(deckId));
  return items.where((i) => i.isDue).toList();
});

final totalDueTodayProvider = Provider<int>((ref) {
  return mockDecks.fold(0, (sum, deck) => sum + deck.dueToday);
});
