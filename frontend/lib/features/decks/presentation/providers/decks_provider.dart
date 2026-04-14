import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/db/app_database.dart' hide Deck;
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/models/item.dart' as model;

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  final rows = await db.getAllDecks();
  final result = <Deck>[];

  for (final row in rows) {
    final allItems = await db.getItemsForDeck(row.id);
    final dueItems = await db.getDueItems(row.id);
    final learned = allItems.where((i) => i.repetitions >= 3).length;

    final newCount = allItems.where((i) => i.repetitions == 0).length;
    final learningCount = allItems.where((i) => i.repetitions > 0 && i.interval < 21).length;
    final reviewCount = allItems.where((i) => i.interval >= 21).length;

    double avgEase = 2.5;
    if (allItems.isNotEmpty) {
      avgEase = allItems.map((i) => i.easeFactor).reduce((a, b) => a + b) / allItems.length;
    }

    result.add(Deck(
      id: row.id,
      name: row.name,
      description: row.description,
      type: DeckType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => DeckType.general,
      ),
      accentColorIndex: row.accentColorIndex,
      emoji: row.emoji,
      totalItems: allItems.length,
      dueToday: dueItems.length,
      learned: learned,
      createdAt: row.createdAt,
      newCount: newCount,
      learningCount: learningCount,
      reviewCount: reviewCount,
      totalReviews: allItems.fold(0, (sum, i) => sum + i.repetitions),
      averageEase: avgEase,
    ));
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

final itemsForDeckProvider = FutureProvider.family<List<model.Item>, String>((ref, deckId) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  final rows = await db.getItemsForDeck(deckId);
  return rows.map((Item row) => model.Item(
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
    )).toList();
});

final dueItemsProvider = FutureProvider.family<List<model.Item>, String>((ref, deckId) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  final rows = await db.getDueItems(deckId);
  return rows.map((Item row) => model.Item(
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
    )).toList();
});

final totalDueTodayProvider = FutureProvider<int>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  return db.getTotalDueToday();
});