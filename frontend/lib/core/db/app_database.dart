import 'package:drift/drift.dart';

// --- Platform-specific DB opening ---
import 'connection_stub.dart'
    if (dart.library.ffi) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';

part 'app_database.g.dart';

// --- Tables ---

class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get type => text()();
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
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
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
  TextColumn get rating => text()();
  IntColumn get intervalBefore => integer()();
  IntColumn get intervalAfter => integer()();
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Database ---

@DriftDatabase(tables: [Decks, Items, ReviewLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openAppDb());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async { await m.createAll(); },
  );

  // Deck queries
  Future<List<Deck>> getAllDecks() => select(decks).get();
  Stream<List<Deck>> watchAllDecks() => select(decks).watch();
  Future<void> upsertDeck(DecksCompanion deck) => into(decks).insertOnConflictUpdate(deck);

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

  Future<void> upsertItem(ItemsCompanion item) => into(items).insertOnConflictUpdate(item);

  Future<void> updateItemSrs(String itemId, {required double easeFactor, required int interval, required int repetitions, required DateTime nextReviewAt}) =>
      (update(items)..where((i) => i.id.equals(itemId))).write(ItemsCompanion(
        easeFactor: Value(easeFactor),
        interval: Value(interval),
        repetitions: Value(repetitions),
        nextReviewAt: Value(nextReviewAt),
        lastReviewedAt: Value(DateTime.now()),
      ));

  Future<void> logReview(ReviewLogsCompanion log) => into(reviewLogs).insert(log);

  // Stats
  Future<int> getDueCount(String deckId) async { final due = await getDueItems(deckId); return due.length; }

  Future<int> getTotalDueToday() async {
    final now = DateTime.now();
    final result = await (select(items)
          ..where((i) => i.nextReviewAt.isNull() | i.nextReviewAt.isSmallerOrEqualValue(now)))
        .get();
    return result.length;
  }

  Future<Map<int, int>> getActivityData({int days = 64}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: days));
    final logs = await (select(reviewLogs)..where((r) => r.reviewedAt.isBiggerOrEqualValue(since))).get();
    final Map<int, int> activity = {};
    for (final log in logs) {
      final daysAgo = now.difference(log.reviewedAt).inDays;
      activity[daysAgo] = (activity[daysAgo] ?? 0) + 1;
    }
    return activity;
  }

  Future<int> getStreak() async {
    final activity = await getActivityData();
    int streak = 0;
    for (int i = 0; i <= 365; i++) {
      if ((activity[i] ?? 0) > 0) {
        streak++;
      } else if (i > 0) { break; }
    }
    return streak;
  }

  Future<int> getTotalReviews() async {
    final count = await customSelect('SELECT COUNT(*) AS c FROM review_logs', readsFrom: {reviewLogs}).getSingle();
    return count.read<int>('c');
  }
}