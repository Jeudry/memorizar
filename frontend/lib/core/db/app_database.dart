import 'package:drift/drift.dart';
import 'connection_stub.dart'
    if (dart.library.ffi) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';

part 'app_database.g.dart';

// --- Tables ---

@DataClassName('DeckRow')
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

@DataClassName('ItemRow')
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

@DataClassName('ReviewLog')
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get rating => text()(); // again | hard | good | easy
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
    onCreate: (m) async {
      await m.createAll();
    },
  );

  // ── Deck queries ────────────────────────────────────────────────────────────

  Future<List<DeckRow>> getAllDecks() => select(decks).get();

  Stream<List<DeckRow>> watchAllDecks() => select(decks).watch();

  Future<void> upsertDeck(DecksCompanion deck) =>
      into(decks).insertOnConflictUpdate(deck);

  // ── Item queries ────────────────────────────────────────────────────────────

  Future<List<ItemRow>> getItemsForDeck(String deckId) =>
      (select(items)..where((i) => i.deckId.equals(deckId))).get();

  Future<List<ItemRow>> getDueItems(String deckId) {
    final now = DateTime.now();
    return (select(items)
          ..where((i) => i.deckId.equals(deckId))
          ..where((i) =>
              i.nextReviewAt.isNull() |
              i.nextReviewAt.isSmallerOrEqualValue(now)))
        .get();
  }

  Future<List<ItemRow>> getAllDueItems() {
    final now = DateTime.now();
    return (select(items)
          ..where((i) =>
              i.nextReviewAt.isNull() |
              i.nextReviewAt.isSmallerOrEqualValue(now)))
        .get();
  }

  Future<void> upsertItem(ItemsCompanion item) =>
      into(items).insertOnConflictUpdate(item);

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

  // ── Review log queries ──────────────────────────────────────────────────────

  Future<void> logReview(ReviewLogsCompanion log) =>
      into(reviewLogs).insert(log);

  /// Returns a map of daysAgo → review count for the last [days] days.
  Future<Map<int, int>> getActivityData({int days = 64}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: days));
    final logs = await (select(reviewLogs)
          ..where((r) => r.reviewedAt.isBiggerOrEqualValue(since)))
        .get();

    final Map<int, int> activity = {};
    for (final log in logs) {
      final daysAgo = now.difference(log.reviewedAt).inDays;
      activity[daysAgo] = (activity[daysAgo] ?? 0) + 1;
    }
    return activity;
  }

  /// Consecutive days ending today where at least one review was made.
  Future<int> getStreak() async {
    final activity = await getActivityData();
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

  /// Total reviews ever logged.
  Future<int> getTotalReviews() async {
    final count = await customSelect(
      'SELECT COUNT(*) AS c FROM review_logs',
      readsFrom: {reviewLogs},
    ).getSingle();
    return count.read<int>('c');
  }
}

