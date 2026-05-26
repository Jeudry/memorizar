import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

@DriftDatabase(tables: [Decks, Cards])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

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

  Future<void> clearAll() async {
    await delete(cards).go();
    await delete(decks).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'memorizar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
