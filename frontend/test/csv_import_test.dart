import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/import/csv_import.dart';

void main() {
  test('CSV con header y comillas', () {
    const content = 'front,back\n'
        '"Salmo 23:1","Jehová es mi pastor, nada me faltará"\n'
        'Juan 3:16,De tal manera amó Dios al mundo\n';
    final result = parseCsvCards(content);
    expect(result.cards, hasLength(2));
    expect(result.cards[0].front, 'Salmo 23:1');
    expect(result.cards[0].back, 'Jehová es mi pastor, nada me faltará',
        reason: 'la coma dentro de comillas no separa columnas');
    expect(result.skippedRows, 0);
  });

  test('TSV sin header y filas inválidas contadas', () {
    const content = 'hola\thello\n'
        'soloUnaColumna\n'
        'adiós\tgoodbye\n'
        '\t\n';
    final result = parseCsvCards(content);
    expect(result.cards, hasLength(2));
    expect(result.cards[1].back, 'goodbye');
    expect(result.skippedRows, 1,
        reason: 'la fila de una columna se salta; la de solo tabs es vacía');
  });

  test('separador punto y coma y comilla escapada', () {
    const content = 'término;"definición con ""cita"" interna"';
    final result = parseCsvCards(content);
    expect(result.cards.single.back, 'definición con "cita" interna');
  });
}
