import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/core/db/app_database.dart';

/// Los grupos (carpetas) organizan mazos: un mazo pertenece a 0 o 1 grupo.
/// Persisten en Drift y al borrar un grupo sus mazos quedan sin grupo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppStore> storeWith2Decks() async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final store = AppStore(enableDatabasePersistence: true, db: db);
    await store.loadDecksFromDatabase();
    store.createDeckFromCards(
      title: 'Mazo A',
      icon: '✝️',
      cards: const [
        MemoryCardData(
            id: 'a1', front: 'f', back: 'b', source: 's', icon: '✝️'),
      ],
    );
    store.createDeckFromCards(
      title: 'Mazo B',
      icon: '📘',
      cards: const [
        MemoryCardData(
            id: 'b1', front: 'f', back: 'b', source: 's', icon: '📘'),
      ],
    );
    return store;
  }

  test('crear grupo, asignar mazo y consultar por grupo', () async {
    final store = await storeWith2Decks();
    final deckA = store.decks.firstWhere((d) => d.title == 'Mazo A');

    final groupId = await store.createGroup('Estudio bíblico');
    expect(store.groups, hasLength(1));
    expect(store.groupById(groupId)!.name, 'Estudio bíblico');

    await store.assignDeckToGroup(deckA.id, groupId);
    expect(store.decksInGroup(groupId).map((d) => d.title), ['Mazo A']);
    // Los sin grupo (null) excluyen el ya agrupado.
    expect(store.decksInGroup(null).map((d) => d.title), contains('Mazo B'));
    expect(store.decksInGroup(null).map((d) => d.title),
        isNot(contains('Mazo A')));
  });

  test('borrar grupo deja los mazos sin grupo (no los borra)', () async {
    final store = await storeWith2Decks();
    final deckA = store.decks.firstWhere((d) => d.title == 'Mazo A');
    final groupId = await store.createGroup('Temporal');
    await store.assignDeckToGroup(deckA.id, groupId);

    await store.deleteGroup(groupId);
    expect(store.groups, isEmpty);
    // El mazo sigue existiendo, solo que sin grupo.
    expect(store.decks.any((d) => d.id == deckA.id), isTrue);
    expect(store.decks.firstWhere((d) => d.id == deckA.id).groupId, isNull);
  });
}
