import 'package:drift/drift.dart';

// Conditional import for multi-platform database connection.
import 'connection_stub.dart'
    if (dart.library.ffi) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';

part 'app_database.g.dart';

// --- Tables ---

class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get type => text()(); // bible | language | general
  IntColumn get accentColorIndex => integer().withDefault(const Constant(0))();
  TextColumn get emoji => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  // SRS
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  // Bible metadata
  TextColumn get book => text().nullable()();
  IntColumn get chapter => integer().nullable()();
  IntColumn get verse => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get rating => text()(); // again | hard | good | easy
  IntColumn get intervalBefore => integer()();
  IntColumn get intervalAfter => integer()();
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
}

class MemorizationPlans extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get name => text()();
  TextColumn get difficulty => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MemorizationPlanItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get planId => text().references(MemorizationPlans, #id)();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get position => integer()();
}

class ExerciseAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get stepType => text()();
  TextColumn get level => text().nullable()();
  TextColumn get difficulty => text()();
  RealColumn get score => real()();
  IntColumn get mistakes => integer().withDefault(const Constant(0))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AudioClips extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get localPath => text()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ExerciseConsolidations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get difficulty => text()();
  RealColumn get averageScore => real()();
  IntColumn get totalMistakes => integer().withDefault(const Constant(0))();
  TextColumn get weakestStepType => text().nullable()();
  TextColumn get strongestStepType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CardsConsolidations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deckId => text().references(Decks, #id)();
  RealColumn get averageScore => real()();
  IntColumn get totalMistakes => integer().withDefault(const Constant(0))();
  TextColumn get weakestExerciseType => text().nullable()();
  TextColumn get strongestExerciseType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MemorizationGoals extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get title => text()();
  TextColumn get objective => text()();
  IntColumn get targetItems => integer().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MemorizationJourneys extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get title => text()();
  IntColumn get targetDays => integer()();
  IntColumn get itemsPerDay => integer()();
  IntColumn get targetItemCount => integer()();
  TextColumn get objective => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AchievementUnlocks extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ErrorBankEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get stepType => text()();
  TextColumn get token => text().nullable()();
  TextColumn get errorKind => text()();
  IntColumn get occurrences => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Database ---

@DriftDatabase(tables: [
  Decks,
  Items,
  ReviewLogs,
  MemorizationPlans,
  MemorizationPlanItems,
  ExerciseAttempts,
  AudioClips,
  ExerciseConsolidations,
  CardsConsolidations,
  MemorizationGoals,
  MemorizationJourneys,
  AchievementUnlocks,
  ErrorBankEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(memorizationPlans);
        await m.createTable(memorizationPlanItems);
        await m.createTable(exerciseAttempts);
        await m.createTable(audioClips);
      }
      if (from < 3) {
        await m.createTable(exerciseConsolidations);
      }
      if (from < 4) {
        await m.createTable(cardsConsolidations);
      }
      if (from < 5) {
        await m.createTable(memorizationGoals);
        await m.createTable(memorizationJourneys);
        await m.createTable(achievementUnlocks);
      }
      if (from < 6) {
        await m.createTable(errorBankEntries);
      }
    },
  );

  // Deck queries
  Future<List<Deck>> getAllDecks() => select(decks).get();

  Stream<List<Deck>> watchAllDecks() => select(decks).watch();

  Future<void> upsertDeck(DecksCompanion deck) =>
      into(decks).insertOnConflictUpdate(deck);

  Future<void> deleteDeck(String deckId) async {
    await (delete(items)..where((i) => i.deckId.equals(deckId))).go();
    await (delete(decks)..where((d) => d.id.equals(deckId))).go();
  }

  // Item queries
  Future<List<Item>> getItemsForDeck(String deckId) =>
      (select(items)..where((i) => i.deckId.equals(deckId))).get();

  Future<List<Item>> getDueItems(String deckId) {
    final now = DateTime.now();
    return (select(items)
          ..where((i) => i.deckId.equals(deckId))
          ..where((i) => i.nextReviewAt.isNull() | i.nextReviewAt.isSmallerOrEqualValue(now)))
        .get();
  }

  Future<void> upsertItem(ItemsCompanion item) =>
      into(items).insertOnConflictUpdate(item);

  Future<void> deleteItem(String itemId) =>
      (delete(items)..where((i) => i.id.equals(itemId))).go();

  Future<void> updateItemSrs(
    String itemId, {
    required double easeFactor,
    required int interval,
    required int repetitions,
    required DateTime nextReviewAt,
  }) =>
      (update(items)..where((i) => i.id.equals(itemId))).write(ItemsCompanion(
        easeFactor: Value(easeFactor),
        interval: Value(interval),
        repetitions: Value(repetitions),
        nextReviewAt: Value(nextReviewAt),
        lastReviewedAt: Value(DateTime.now()),
      ));

  Future<void> logReview(ReviewLogsCompanion log) => into(reviewLogs).insert(log);

  // Memorization plans
  Future<List<MemorizationPlan>> getPlansForDeck(String deckId) =>
      (select(memorizationPlans)
            ..where((p) => p.deckId.equals(deckId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  Future<List<MemorizationPlanItem>> getPlanItems(String planId) =>
      (select(memorizationPlanItems)
            ..where((i) => i.planId.equals(planId))
            ..orderBy([(i) => OrderingTerm.asc(i.position)]))
          .get();

  Future<void> createPlan({
    required MemorizationPlansCompanion plan,
    required List<MemorizationPlanItemsCompanion> items,
  }) async {
    await transaction(() async {
      await into(memorizationPlans).insert(plan);
      if (items.isNotEmpty) {
        await batch((batch) => batch.insertAll(memorizationPlanItems, items));
      }
    });
  }

  Future<List<Item>> getItemsForPlan(String planId) async {
    final planRows = await getPlanItems(planId);
    final orderedItems = <Item>[];
    for (final row in planRows) {
      final item = await (select(items)..where((tbl) => tbl.id.equals(row.itemId))).getSingleOrNull();
      if (item != null) {
        orderedItems.add(item);
      }
    }
    return orderedItems;
  }

  Future<void> createGoal(MemorizationGoalsCompanion goal) =>
      into(memorizationGoals).insertOnConflictUpdate(goal);

  Future<List<MemorizationGoal>> getGoalsForDeck(String deckId) =>
      (select(memorizationGoals)
            ..where((g) => g.deckId.equals(deckId))
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .get();

  Future<void> createJourney(MemorizationJourneysCompanion journey) =>
      into(memorizationJourneys).insertOnConflictUpdate(journey);

  Future<List<MemorizationJourney>> getJourneysForDeck(String deckId) =>
      (select(memorizationJourneys)
            ..where((j) => j.deckId.equals(deckId))
            ..orderBy([(j) => OrderingTerm.desc(j.createdAt)]))
          .get();

  Future<void> unlockAchievement(AchievementUnlocksCompanion achievement) =>
      into(achievementUnlocks).insertOnConflictUpdate(achievement);

  Future<List<AchievementUnlock>> getAchievements() =>
      (select(achievementUnlocks)..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)])).get();

  Future<void> logExerciseAttempt(ExerciseAttemptsCompanion attempt) =>
      into(exerciseAttempts).insert(attempt);

  Future<void> saveAudioClip(AudioClipsCompanion clip) => into(audioClips).insert(clip);

  Future<void> saveExerciseConsolidation(ExerciseConsolidationsCompanion consolidation) =>
      into(exerciseConsolidations).insert(consolidation);

  Future<List<ExerciseConsolidation>> getRecentConsolidationsForDeck(String deckId, {int limit = 8}) =>
      (select(exerciseConsolidations)
            ..where((c) => c.deckId.equals(deckId))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
            ..limit(limit))
          .get();

  Future<List<ExerciseConsolidation>> getRecentConsolidationsForItem(String itemId, {int limit = 8}) =>
      (select(exerciseConsolidations)
            ..where((c) => c.itemId.equals(itemId))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
            ..limit(limit))
          .get();

  Future<List<ExerciseConsolidation>> getRecentConsolidations({int limit = 24}) =>
      (select(exerciseConsolidations)
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
            ..limit(limit))
          .get();

  Future<void> saveCardsConsolidation(CardsConsolidationsCompanion consolidation) =>
      into(cardsConsolidations).insert(consolidation);

  Future<List<CardsConsolidation>> getRecentCardsConsolidationsForDeck(String deckId, {int limit = 8}) =>
      (select(cardsConsolidations)
            ..where((c) => c.deckId.equals(deckId))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
            ..limit(limit))
          .get();

  Future<List<CardsConsolidation>> getRecentCardsConsolidations({int limit = 24}) =>
      (select(cardsConsolidations)
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
            ..limit(limit))
          .get();

  Future<List<ExerciseAttempt>> getExerciseAttemptsForItems(List<String> itemIds, {int limit = 200}) async {
    if (itemIds.isEmpty) return const [];
    return (select(exerciseAttempts)
          ..where((a) => a.itemId.isIn(itemIds))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> logErrorBankEntries(List<ErrorBankEntriesCompanion> entries) async {
    if (entries.isEmpty) return;
    await batch((batch) => batch.insertAll(errorBankEntries, entries));
  }

  Future<List<ErrorBankEntry>> getRecentErrorBankEntriesForItems(List<String> itemIds, {int limit = 200}) async {
    if (itemIds.isEmpty) return const [];
    return (select(errorBankEntries)
          ..where((entry) => entry.itemId.isIn(itemIds))
          ..orderBy([(entry) => OrderingTerm.desc(entry.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<AudioClip?> getLatestAudioClip(String itemId) =>
      (select(audioClips)
            ..where((c) => c.itemId.equals(itemId))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  // Stats
  Future<int> getDueCount(String deckId) async {
    final due = await getDueItems(deckId);
    return due.length;
  }

  Future<int> getTotalDueToday() async {
    final now = DateTime.now();
    final result = await (select(items)
          ..where((i) => i.nextReviewAt.isNull() | i.nextReviewAt.isSmallerOrEqualValue(now)))
        .get();
    return result.length;
  }

  /// Returns review counts per day for the last `days` days.
  /// Key: days ago (0 = today), Value: number of reviews
  Future<Map<int, int>> getActivityData({int days = 63}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final logs = await (select(reviewLogs)
          ..where((l) => l.reviewedAt.isBiggerOrEqualValue(start)))
        .get();

    final map = <int, int>{};
    for (int i = 0; i <= days; i++) {
      map[i] = 0;
    }
    for (final log in logs) {
      final daysAgo = now.difference(log.reviewedAt).inDays;
      map[daysAgo] = (map[daysAgo] ?? 0) + 1;
    }
    return map;
  }

  /// Consecutive days with at least one review, counting backwards from today.
  Future<int> getStreak() async {
    final activity = await getActivityData(days: 365);
    int streak = 0;
    for (int i = 0; i <= 365; i++) {
      if ((activity[i] ?? 0) > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  Future<int> getTotalReviews() async {
    final logs = await select(reviewLogs).get();
    return logs.length;
  }
}
