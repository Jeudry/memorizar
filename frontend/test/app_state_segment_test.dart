import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';

void main() {
  test('segmentContent creates one card per pasted line', () {
    final store = AppStore();

    final cards = store.segmentContent('Capital: Santo Domingo\nMoneda: Peso');

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Capital');
    expect(cards.first.back, 'Santo Domingo');
    expect(cards.last.front, 'Moneda');
    expect(cards.last.back, 'Peso');
  });

  test('segmentContent preserves Bible references with chapter and verse', () {
    final store = AppStore();

    final cards = store.segmentContent(
      'Juan 3:16 Porque de tal manera amó Dios al mundo',
    );

    expect(cards, hasLength(1));
    expect(cards.single.front, 'Juan 3:16');
    expect(cards.single.back, 'Porque de tal manera amó Dios al mundo');
  });

  test('segmentContent groups wrapped Bible verse lines by verse number', () {
    final store = AppStore();

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
    final store = AppStore();

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
    final store = AppStore();

    final cards = store.segmentContent(
      'Primera idea importante. Segunda idea para practicar.',
    );

    expect(cards, hasLength(2));
    expect(cards.first.front, 'Tarjeta 1');
    expect(cards.first.back, 'Primera idea importante.');
  });
}
