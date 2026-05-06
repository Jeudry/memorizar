import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/models/item.dart';

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  final database = ref.watch(databaseProvider);
  final dbDecks = await database.getAllDecks();

  final decks = <Deck>[];
  for (final dd in dbDecks) {
    final items = await database.getItemsForDeck(dd.id);
    final totalItems = items.length;
    final dueToday = await database.getDueCount(dd.id);
    final learned = items.where((i) => i.repetitions > 0).length;

    decks.add(Deck(
      id: dd.id,
      name: dd.name,
      description: dd.description,
      type: _stringToDeckType(dd.type),
      accentColorIndex: dd.accentColorIndex,
      emoji: dd.emoji,
      createdAt: dd.createdAt,
      totalItems: totalItems,
      dueToday: dueToday,
      learned: learned,
    ));
  }
  return decks;
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
  final database = ref.watch(databaseProvider);
  final rows = await database.getItemsForDeck(deckId);
  return rows.map(_dbItemToItem).toList();
});

final dueItemsProvider = FutureProvider.family<List<Item>, String>((ref, deckId) async {
  final database = ref.watch(databaseProvider);
  final rows = await database.getDueItems(deckId);
  return rows.map(_dbItemToItem).toList();
});

final totalDueTodayProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getTotalDueToday();
});

DeckType _stringToDeckType(String s) {
  switch (s) {
    case 'bible':
      return DeckType.bible;
    case 'language':
      return DeckType.language;
    default:
      return DeckType.general;
  }
}

Item _dbItemToItem(db.Item row) => Item(
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
