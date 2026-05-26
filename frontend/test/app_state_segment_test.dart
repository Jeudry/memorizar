import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/core/db/app_database.dart';

void main() {
  test('segmentContent creates one card per pasted line', () {
    final store = AppStore(enableDatabasePersistence: false);

    final cards = store.segmentContent('Capital: Santo Domingo\nMoneda: Peso');

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Capital');
    expect(cards.first.back, 'Santo Domingo');
    expect(cards.last.front, 'Moneda');
    expect(cards.last.back, 'Peso');
  });

  test('segmentContent preserves Bible references with chapter and verse', () {
    final store = AppStore(enableDatabasePersistence: false);

    final cards = store.segmentContent(
      'Juan 3:16 Porque de tal manera amó Dios al mundo',
    );

    expect(cards, hasLength(1));
    expect(cards.single.front, 'Juan 3:16');
    expect(cards.single.back, 'Porque de tal manera amó Dios al mundo');
  });

  test('segmentContent groups wrapped Bible verse lines by verse number', () {
    final store = AppStore(enableDatabasePersistence: false);

    final cards = store.segmentContent('''
1 Aleluya. Alabad a Jehová, porque él es bueno;
Porque para siempre es su misericordia.
2 ¿Quién expresará las valentías de Jehová?
¿Quién contará sus alabanzas?
5 Para que yo vea la prosperidad de tus escogidos,
Para que me regocije en la alegría de tu nación,
Para que me gloríe con tu heredad.
''', title: 'Salmos 106:1-5');

    expect(cards, hasLength(3));
    expect(cards.first.front, 'Salmos 106:1');
    expect(
      cards.first.back,
      'Aleluya. Alabad a Jehová, porque él es bueno; Porque para siempre es su misericordia.',
    );
    expect(cards[1].front, 'Salmos 106:2');
    expect(cards.last.front, 'Salmos 106:5');
    expect(
      cards.last.back,
      'Para que yo vea la prosperidad de tus escogidos, Para que me regocije en la alegría de tu nación, Para que me gloríe con tu heredad.',
    );
  });

  test('segmentContent groups verse lines without title or number spacing', () {
    final store = AppStore(enableDatabasePersistence: false);

    final cards = store.segmentContent('''
1¡Aleluya!
Den gracias al Señor, porque es bueno;
Porque para siempre es Su misericordia.
2 ¿Quién puede relatar los poderosos hechos del Señor,
O expresar toda Su alabanza?
''');

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Versículo 1');
    expect(
      cards.first.back,
      '¡Aleluya! Den gracias al Señor, porque es bueno; Porque para siempre es Su misericordia.',
    );
    expect(cards.last.front, 'Versículo 2');
    expect(
      cards.last.back,
      '¿Quién puede relatar los poderosos hechos del Señor, O expresar toda Su alabanza?',
    );
  });

  test('segmentContent splits one pasted paragraph into sentence cards', () {
    final store = AppStore(enableDatabasePersistence: false);

    final cards = store.segmentContent(
      'Primera idea importante. Segunda idea para practicar.',
    );

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Tarjeta 1');
    expect(cards.first.back, 'Primera idea importante.');
  });

  test('segmentContent matches verse numbers in brackets and parentheses', () {
    final store = AppStore(enableDatabasePersistence: false);
    final cards = store.segmentContent('''
[1] Den gracias al Señor, porque Él es bueno;
(2) Díganlo los redimidos
''', title: 'Salmo 107:1-2');

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Salmo 107:1');
    expect(cards.first.back, 'Den gracias al Señor, porque Él es bueno;');
    expect(cards.last.front, 'Salmo 107:2');
    expect(cards.last.back, 'Díganlo los redimidos');
  });

  test('segmentContent performs ultimate smart title extraction, url stripping, and same-line verse splitting', () {
    final store = AppStore(enableDatabasePersistence: false);
    final cards = store.segmentContent('''
Salmo 107:1-2 NBLA
[1] Den gracias al Señor, porque Él es bueno; Porque para siempre es Su misericordia. [2] Díganlo los redimidos del Señor, A quienes ha redimido de la mano del adversario,

https://bible.com/bible/103/psa.107.1-2.NBLA
''');

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Salmo 107:1');
    expect(cards.first.back, 'Den gracias al Señor, porque Él es bueno; Porque para siempre es Su misericordia.');
    expect(cards.last.front, 'Salmo 107:2');
    expect(cards.last.back, 'Díganlo los redimidos del Señor, A quienes ha redimido de la mano del adversario,');
  });

  test('segmentContent performs dynamic verse grouping even when first verse marker is eaten or omitted', () {
    final store = AppStore(enableDatabasePersistence: false);
    final cards = store.segmentContent('''
Den gracias al Señor, porque Él es bueno;
Porque para siempre es Su misericordia.
2 Díganlo los redimidos del Señor,
A quienes ha redimido de la mano del adversario,
''');

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Versículo 1');
    expect(cards.first.back, 'Den gracias al Señor, porque Él es bueno; Porque para siempre es Su misericordia.');
    expect(cards.last.front, 'Versículo 2');
    expect(cards.last.back, 'Díganlo los redimidos del Señor, A quienes ha redimido de la mano del adversario,');
  });

  test('segmentContent handles key-value lists and bullet lists separately per line', () {
    final store = AppStore(enableDatabasePersistence: false);
    final listCards = store.segmentContent('''
Capital: Santo Domingo
Moneda: Peso
Idioma: Español
''');
    expect(listCards, hasLength(3));
    expect(listCards[0].front, 'Capital');
    expect(listCards[0].back, 'Santo Domingo');
    expect(listCards[1].front, 'Moneda');
    expect(listCards[1].back, 'Peso');
    expect(listCards[2].front, 'Idioma');
    expect(listCards[2].back, 'Español');

    final bulletCards = store.segmentContent('''
- Primera cosa importante
- Segunda cosa importante
''');
    expect(bulletCards, hasLength(2));
    expect(bulletCards[0].front, 'Tarjeta 1');
    expect(bulletCards[0].back, 'Primera cosa importante');
    expect(bulletCards[1].front, 'Tarjeta 2');
    expect(bulletCards[1].back, 'Segunda cosa importante');
  });

  test('segmentContent joins wrapped paragraph lines into a single sentence card', () {
    final store = AppStore(enableDatabasePersistence: false);
    final cards = store.segmentContent('''
En la antigüedad, las personas
solían memorizar textos enteros
de memoria para preservar su cultura.
''');
    expect(cards, hasLength(1));
    expect(cards[0].front, 'Tarjeta 1');
    expect(cards[0].back, 'En la antigüedad, las personas solían memorizar textos enteros de memoria para preservar su cultura.');
  });
}
