import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/features/home/presentation/screens/practice_choose_word_screen.dart';

/// Práctica de "Elige la palabra correcta": sin niveles ni intentos, banco
/// completo, hay que completar el versículo DOS veces para terminar.
void main() {
  Future<void> pumpScreen(WidgetTester tester, AppStore store) async {
    await tester.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(
        home: Scaffold(
          body: ChooseWordPracticeBody(
            card: store.activeCard,
            onFinished: () {},
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('completar el versículo 2 veces muestra el éxito',
      (tester) async {
    final store = AppStore(enableDatabasePersistence: false);
    store.createDeckFromCards(
      title: 'Test',
      icon: '✝️',
      cards: const [
        MemoryCardData(
          id: 'c1',
          front: 'Salmo 23:1',
          back: 'Jehová es mi pastor',
          source: 'RV1909',
          icon: '✝️',
        ),
      ],
    );

    await pumpScreen(tester, store);

    // El banco se muestra y arranca en la vuelta 1.
    expect(find.text('BANCO COMPLETO · TOCA LA PALABRA'), findsOneWidget);
    expect(find.textContaining('Vuelta 1/2'), findsOneWidget);

    // Huecos = palabras de >3 letras, en orden: "Jehová", "pastor".
    // (En el banco las palabras son únicas; .last desambigua del hueco lleno.)
    for (var pass = 0; pass < 2; pass++) {
      for (final word in ['Jehová', 'pastor']) {
        await tester.tap(find.text(word).last);
        await tester.pump();
      }
    }

    expect(find.text('🎉'), findsOneWidget);
    expect(find.text('¡Lo completaste 2 veces!'), findsOneWidget);
  });

  testWidgets('tocar una palabra incorrecta no avanza (sin penalización)',
      (tester) async {
    final store = AppStore(enableDatabasePersistence: false);
    store.createDeckFromCards(
      title: 'Test',
      icon: '✝️',
      cards: const [
        MemoryCardData(
          id: 'c1',
          front: 'Salmo 23:1',
          back: 'Jehová es mi pastor',
          source: 'RV1909',
          icon: '✝️',
        ),
      ],
    );

    await pumpScreen(tester, store);

    // Arranca con 0 huecos llenos.
    expect(find.textContaining('· 0/2'), findsOneWidget);

    // El primer hueco correcto es "Jehová"; tocar "pastor" es incorrecto:
    // no llena nada (sin penalización pero sin avanzar). El parpadeo rojo usa
    // un timer de 400ms — lo dejamos disparar para no dejar timers pendientes.
    await tester.tap(find.text('pastor').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('· 0/2'), findsOneWidget);
    expect(find.text('¡Lo completaste 2 veces!'), findsNothing);

    // Tocar el correcto sí avanza a 1/2.
    await tester.tap(find.text('Jehová').last);
    await tester.pump();
    expect(find.textContaining('· 1/2'), findsOneWidget);
  });
}
