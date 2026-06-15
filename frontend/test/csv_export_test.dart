import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/import/csv_export.dart';
import 'package:frontend/core/import/csv_import.dart';

void main() {
  test('exporta header + filas, citando lo necesario', () {
    final csv = cardsToCsv(const [
      CsvExportCard(front: 'Juan 3:16', back: 'De tal manera amó Dios'),
      CsvExportCard(front: 'Salmo 23:1', back: 'Jehová es mi pastor, nada'),
    ]);
    final lines = csv.trim().split('\r\n');
    expect(lines.first, 'front,back');
    expect(lines[1], 'Juan 3:16,De tal manera amó Dios');
    // La coma dentro del dorso fuerza comillas.
    expect(lines[2], 'Salmo 23:1,"Jehová es mi pastor, nada"');
  });

  test('escapa comillas dobles como ""', () {
    final csv = cardsToCsv(const [
      CsvExportCard(front: 'cita', back: 'dijo "hola" fuerte'),
    ]);
    expect(csv.contains('"dijo ""hola"" fuerte"'), isTrue);
  });

  test('round-trip: exportar y re-importar devuelve las mismas tarjetas', () {
    // (Tarjetas de versículo no traen saltos de línea; el parser de import
    // separa por líneas, así que el round-trip cubre comas y comillas.)
    const original = [
      CsvExportCard(front: 'A', back: 'texto con, coma'),
      CsvExportCard(front: 'B', back: 'con "comillas" internas'),
      CsvExportCard(front: 'C', back: 'simple'),
    ];
    final csv = cardsToCsv(original);
    final parsed = parseCsvCards(csv);
    expect(parsed.cards, hasLength(3));
    expect(parsed.skippedRows, 0);
    for (var i = 0; i < original.length; i++) {
      expect(parsed.cards[i].front, original[i].front);
      expect(parsed.cards[i].back, original[i].back);
    }
  });
}
