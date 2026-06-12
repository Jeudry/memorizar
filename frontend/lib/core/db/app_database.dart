import 'package:drift/drift.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  TextColumn get icon => text()();
  BoolColumn get isBible => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get source => text()();
  TextColumn get icon => text()();
  IntColumn get retention => integer().withDefault(const Constant(82))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Actividad agregada por día local (clave 'YYYY-MM-DD'). Alimenta la racha
/// real y los filtros de período de la pantalla de estadísticas.
class DailyActivity extends Table {
  TextColumn get day => text()();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  IntColumn get wrong => integer().withDefault(const Constant(0))();
  IntColumn get cardsReviewed => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {day};
}

@DriftDatabase(tables: [Decks, Cards, DailyActivity])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());
  AppDatabase.memory() : super(impl.connect(inMemory: true));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(dailyActivity);
          }
        },
      );

  // Deck queries
  Future<List<Deck>> getAllDecks() => select(decks).get();

  Stream<List<Deck>> watchAllDecks() => select(decks).watch();

  Future<void> upsertDeck(DecksCompanion deck) =>
      into(decks).insertOnConflictUpdate(deck);

  Future<void> deleteDeck(String deckId) =>
      (delete(decks)..where((d) => d.id.equals(deckId))).go();

  // Card queries
  Future<List<Card>> getCardsForDeck(String deckId) =>
      (select(cards)..where((c) => c.deckId.equals(deckId))).get();

  Future<void> upsertCard(CardsCompanion card) =>
      into(cards).insertOnConflictUpdate(card);

  Future<void> updateCardRetention(String cardId, int retention, int lapses) =>
      (update(cards)..where((c) => c.id.equals(cardId))).write(CardsCompanion(
        retention: Value(retention),
        lapses: Value(lapses),
      ));

  // Daily activity queries
  Future<void> recordDailyActivity({
    required String day,
    int correctDelta = 0,
    int wrongDelta = 0,
    int reviewedDelta = 0,
  }) {
    return customStatement(
      'INSERT INTO daily_activity (day, correct, wrong, cards_reviewed) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(day) DO UPDATE SET '
      'correct = correct + excluded.correct, '
      'wrong = wrong + excluded.wrong, '
      'cards_reviewed = cards_reviewed + excluded.cards_reviewed',
      [day, correctDelta, wrongDelta, reviewedDelta],
    );
  }

  Future<List<DailyActivityData>> getAllDailyActivity() =>
      (select(dailyActivity)
            ..orderBy([(t) => OrderingTerm.desc(t.day)]))
          .get();

  Future<void> clearAll() async {
    await delete(cards).go();
    await delete(decks).go();
    await delete(dailyActivity).go();
  }
}

