import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/models/item.dart';

// ── Decks ─────────────────────────────────────────────────────────────────────

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);

  final rows = await db.getAllDecks();
  final result = <Deck>[];

  for (final row in rows) {
    final allItems = await db.getItemsForDeck(row.id);
    final dueItems = await db.getDueItems(row.id);
    final learned = allItems.where((i) => i.repetitions >= 3).length;

    result.add(_rowToDeck(row, allItems.length, dueItems.length, learned));
  }

  return result;
});

final deckByIdProvider = FutureProvider.family<Deck?, String>((ref, id) async {
  final decks = await ref.watch(decksProvider.future);
  try {
    return decks.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
});

final itemsForDeckProvider = FutureProvider.family<List<Item>, String>((ref, deckId) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  final rows = await db.getItemsForDeck(deckId);
  return rows.map(_rowToItem).toList();
});

final dueItemsProvider = FutureProvider.family<List<Item>, String>((ref, deckId) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  final rows = await db.getDueItems(deckId);
  return rows.map(_rowToItem).toList();
});

final totalDueTodayProvider = FutureProvider<int>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  final rows = await db.getAllDueItems();
  return rows.length;
});

// ── Mapping helpers ───────────────────────────────────────────────────────────

Deck _rowToDeck(DeckRow row, int totalItems, int dueToday, int learned) => Deck(
      id: row.id,
      name: row.name,
      description: row.description,
      type: DeckType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => DeckType.general,
      ),
      accentColorIndex: row.accentColorIndex,
      emoji: row.emoji,
      totalItems: totalItems,
      dueToday: dueToday,
      learned: learned,
      createdAt: row.createdAt,
    );

Item _rowToItem(ItemRow row) => Item(
      id: row.id,
      deckId: row.deckId,
      front: row.front,
      back: row.back,
      easeFactor: row.easeFactor,
      interval: row.interval,
      repetitions: row.repetitions,
      nextReviewAt: row.nextReviewAt,
      lastReviewedAt: row.lastReviewedAt,
      book: row.book,
      chapter: row.chapter,
      verse: row.verse,
    );
