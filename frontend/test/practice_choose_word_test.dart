import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/features/home/presentation/screens/practice_choose_word_screen.dart';

/// Práctica de "Elige la palabra correcta": sin niveles ni intentos, oculta el
/// 50% de las palabras (aleatorio) y hay que completar el versículo para
/// terminar. Como los huecos son aleatorios, los tests no dependen de CUÁLES
/// palabras se ocultan: recorren el versículo tocando la opción correcta del
/// hueco activo hasta completar.
void main() {
  Future<void> pumpScreen(WidgetTester tester, AppStore store) async {
    await tester.pumpWidget(AppScope(
      store: store,
      child: MaterialApp(
        home: Scaffold(
          body: ChooseWordPracticeBody(
            cardId: store.activeCard.id,
            targetText: store.activeCard.back,
            reference: store.activeCard.front,
            onFinished: () {},
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  AppStore buildStore() {
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
    return store;
  }

  /// Toca la opción (botón) cuya palabra coincide con [word], si está visible
  /// entre las opciones del hueco activo. Devuelve true si tocó algo.
  Future<bool> tapOption(WidgetTester tester, String word) async {
    final option = find.widgetWithText(GestureDetector, word);
    if (option.evaluate().isEmpty) return false;
    await tester.tap(option.last);
    await tester.pump();
    // El parpadeo rojo del fallo usa un timer de 400ms: lo dejamos disparar
    // para no dejar timers pendientes.
    await tester.pump(const Duration(milliseconds: 450));
    return true;
  }

  testWidgets('completar el versículo muestra el éxito', (tester) async {
    await pumpScreen(tester, buildStore());

    expect(find.text('ELIGE LA PALABRA CORRECTA'), findsOneWidget);

    // Recorremos las palabras en orden del texto: la del hueco activo avanza;
    // las incorrectas solo parpadean. Como los huecos van en orden, al terminar
    // el recorrido quedan todos llenos.
    for (final word in ['Jehová', 'es', 'mi', 'pastor']) {
      if (find.text('¡Lo completaste!').evaluate().isNotEmpty) break;
      await tapOption(tester, word);
    }

    expect(find.text('🎉'), findsOneWidget);
    expect(find.text('¡Lo completaste!'), findsOneWidget);
  });

  testWidgets('una sola acción no completa (quedan huecos)', (tester) async {
    await pumpScreen(tester, buildStore());

    // 4 palabras → 50% = 2 huecos, así que una sola acción nunca completa.
    expect(find.text('¡Lo completaste!'), findsNothing);

    // Toca una única opción del hueco activo (una de las palabras del texto
    // está entre las opciones): con 2 huecos, no puede completar todavía.
    for (final word in ['Jehová', 'es', 'mi', 'pastor']) {
      if (await tapOption(tester, word)) break;
    }

    expect(find.text('¡Lo completaste!'), findsNothing);
  });
}
