import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart';
import 'package:memorizar/features/decks/data/mock_data.dart';
import 'package:memorizar/features/decks/data/models/item.dart' as model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

/// Singleton database instance for the app lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Ensures the DB is seeded on first launch.
final dbReadyProvider = FutureProvider<void>((ref) async {
  try {
    final db = ref.read(databaseProvider);
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('memorizar_seeded') ?? false) return;

    debugPrint('[Seed] Starting seed...');

    for (final deck in mockDecks) {
      await db.upsertDeck(DecksCompanion.insert(
        id: deck.id,
        name: deck.name,
        description: deck.description,
        type: deck.type.name,
        accentColorIndex: Value(deck.accentColorIndex),
        emoji: Value(deck.emoji),
        createdAt: Value(deck.createdAt),
      ));
    }

    for (final items in allMockItems.values) {
      for (final item in items) {
        await db.upsertItem(_itemToCompanion(item));
      }
    }

    await prefs.setBool('memorizar_seeded', true);
    debugPrint('[Seed] Done!');
  } catch (e, st) {
    debugPrint('[Seed] ERROR: $e\n$st');
    rethrow;
  }
});

ItemsCompanion _itemToCompanion(model.Item item) => ItemsCompanion.insert(
      id: item.id,
      deckId: item.deckId,
      front: item.front,
      back: item.back,
      easeFactor: Value(item.easeFactor),
      interval: Value(item.interval),
      repetitions: Value(item.repetitions),
      nextReviewAt: Value(item.nextReviewAt),
      lastReviewedAt: Value(item.lastReviewedAt),
      book: Value(item.book),
      chapter: Value(item.chapter),
      verse: Value(item.verse),
    );