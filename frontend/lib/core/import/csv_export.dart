/// Serializa tarjetas (frente, dorso) a CSV estándar, compatible con el
/// parser de importación ([parseCsvCards]). Header `front,back`, comillas
/// dobles cuando el campo tiene coma/comilla/salto de línea, escapando `"`
/// como `""`.
library;

/// Par frente/dorso a exportar. Desacoplado de MemoryCardData para mantener
/// esta lógica pura y testeable.
class CsvExportCard {
  final String front;
  final String back;
  const CsvExportCard({required this.front, required this.back});
}

String _csvField(String value) {
  final needsQuotes =
      value.contains(',') || value.contains('"') || value.contains('\n') ||
          value.contains('\r');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

/// Devuelve el contenido CSV (con header) de la lista de tarjetas.
String cardsToCsv(List<CsvExportCard> cards) {
  final buffer = StringBuffer('front,back\r\n');
  for (final card in cards) {
    buffer.write(_csvField(card.front));
    buffer.write(',');
    buffer.write(_csvField(card.back));
    buffer.write('\r\n');
  }
  return buffer.toString();
}
