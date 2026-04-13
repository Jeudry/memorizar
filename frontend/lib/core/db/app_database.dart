import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

// --- Database ---

@DriftDatabase(tables: [Decks, Items, ReviewLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );

  // Deck queries
  Future<List<Deck>> getAllDecks() => select(decks).get();

  Stream<List<Deck>> watchAllDecks() => select(decks).watch();

  Future<void> upsertDeck(DecksCompanion deck) =>
      into(decks).insertOnConflictUpdate(deck);

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'memorizar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
