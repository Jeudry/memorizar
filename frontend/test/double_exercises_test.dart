import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/core/db/app_database.dart';

/// El modo experimental "duplicar ejercicios" hace que cada tarjeta repita su
/// flujo dos veces. La segunda pasada se logra renovando el namespace de pasos
/// completados (`_currentCardPass`), sin tocar rutas ni slugs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppStore> storeWithDeck() async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final store = AppStore(enableDatabasePersistence: true, db: db);
    await store.loadDecksFromDatabase();
    store.createDeckFromCards(
      title: 'Test',
      icon: '✝️',
      cards: const [
        MemoryCardData(
          id: 'c1',
          front: 'Juan 3:16',
          back: 'De tal manera amó Dios al mundo',
          source: 'RV1909',
          icon: '✝️',
        ),
      ],
    );
    return store;
  }

  test('con duplicar activo, la 2da pasada repite y renueva los pasos',
      () async {
    final store = await storeWithDeck();
    store.configureSession(
        difficulty: 1, dailyTarget: 1, doubleExercises: true);

    expect(store.shouldRepeatCardForDouble(), isTrue,
        reason: 'primera pasada → debe repetir');
    store.markExerciseStepCompleted('06-completar-n1');
    expect(store.isExerciseStepCompleted('06-completar-n1'), isTrue);

    store.startSecondPass();
    expect(store.shouldRepeatCardForDouble(), isFalse,
        reason: 'ya en la segunda pasada → no repite otra vez');
    expect(store.isExerciseStepCompleted('06-completar-n1'), isFalse,
        reason: 'la segunda pasada tiene su propio namespace de pasos');
  });

  test('sin duplicar, nunca repite la tarjeta', () async {
    final store = await storeWithDeck();
    store.configureSession(
        difficulty: 1, dailyTarget: 1, doubleExercises: false);
    expect(store.shouldRepeatCardForDouble(), isFalse);
  });
}
