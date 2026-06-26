import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';

/// Borrado múltiple de mazos (selección múltiple en "Mis Mazos").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppStore storeWith3Decks() {
    final store = AppStore(enableDatabasePersistence: false);
    for (final name in const ['Mazo A', 'Mazo B', 'Mazo C']) {
      store.createDeckFromCards(
        title: name,
        icon: '✝️',
        cards: [
          MemoryCardData(
              id: '$name-1', front: 'f', back: 'b', source: 's', icon: '✝️'),
        ],
      );
    }
    return store;
  }

  test('deleteDecks borra varios mazos y conserva el resto', () async {
    final store = storeWith3Decks();
    final a = store.decks.firstWhere((d) => d.title == 'Mazo A').id;
    final b = store.decks.firstWhere((d) => d.title == 'Mazo B').id;
    final c = store.decks.firstWhere((d) => d.title == 'Mazo C').id;

    await store.deleteDecks([a, c]);

    expect(store.decks.any((d) => d.id == a), isFalse);
    expect(store.decks.any((d) => d.id == c), isFalse);
    expect(store.decks.any((d) => d.id == b), isTrue);
  });

  test('deleteDecks con lista vacía no cambia nada', () async {
    final store = storeWith3Decks();
    final before = store.decks.length;

    await store.deleteDecks(const []);

    expect(store.decks, hasLength(before));
  });

  test('deleteDecks ignora ids inexistentes', () async {
    final store = storeWith3Decks();
    final a = store.decks.firstWhere((d) => d.title == 'Mazo A').id;
    final b = store.decks.firstWhere((d) => d.title == 'Mazo B').id;
    final c = store.decks.firstWhere((d) => d.title == 'Mazo C').id;

    await store.deleteDecks([b, 'no-existe']);

    expect(store.decks.any((d) => d.id == b), isFalse);
    expect(store.decks.any((d) => d.id == a), isTrue);
    expect(store.decks.any((d) => d.id == c), isTrue);
  });
}
