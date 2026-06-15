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
  // Estado SM-2: factor de facilidad, intervalo actual en días, repasos
  // consecutivos correctos y próxima fecha de repaso (null = nunca repasada,
  // siempre due).
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(dailyActivity);
          }
          if (from < 3) {
            await m.addColumn(cards, cards.easeFactor);
            await m.addColumn(cards, cards.intervalDays);
            await m.addColumn(cards, cards.repetitions);
            await m.addColumn(cards, cards.nextReviewAt);
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

  Future<void> updateCardSrs(
    String cardId, {
    required int retention,
    required int lapses,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime? nextReviewAt,
  }) =>
      (update(cards)..where((c) => c.id.equals(cardId))).write(CardsCompanion(
        retention: Value(retention),
        lapses: Value(lapses),
        easeFactor: Value(easeFactor),
        intervalDays: Value(intervalDays),
        repetitions: Value(repetitions),
        nextReviewAt: Value(nextReviewAt),
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

