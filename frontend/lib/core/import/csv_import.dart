/// Parser de mazos desde CSV/TSV: dos columnas (frente, dorso) por fila.
/// Detecta el separador (tab, punto y coma o coma), tolera comillas dobles
/// estilo CSV y descarta el header si la primera fila parece uno.
library;

class CsvCard {
  final String front;
  final String back;
  const CsvCard({required this.front, required this.back});
}

class CsvImportResult {
  final List<CsvCard> cards;
  final int skippedRows;
  const CsvImportResult({required this.cards, required this.skippedRows});
}

const _headerWords = {
  'front', 'back', 'frente', 'dorso', 'pregunta', 'respuesta', 'question',
  'answer', 'term', 'definition',
};

String _detectSeparator(String content) {
  final firstLines = content.split('\n').take(5).join('\n');
  if (firstLines.contains('\t')) return '\t';
  if (firstLines.contains(';')) return ';';
  return ',';
}

/// Divide una línea respetando comillas dobles ("a, b",c → [a, b | c]).
List<String> _splitLine(String line, String separator) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      final isEscapedQuote =
          inQuotes && i + 1 < line.length && line[i + 1] == '"';
      if (isEscapedQuote) {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == separator && !inQuotes) {
      fields.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  fields.add(buffer.toString());
  return fields;
}

bool _looksLikeHeader(List<String> fields) {
  if (fields.length < 2) return false;
  final first = fields[0].trim().toLowerCase();
  final second = fields[1].trim().toLowerCase();
  return _headerWords.contains(first) && _headerWords.contains(second);
}

/// Parsea el contenido completo de un archivo CSV/TSV a tarjetas.
/// Filas sin al menos dos columnas con contenido se cuentan como saltadas.
CsvImportResult parseCsvCards(String content) {
  final separator = _detectSeparator(content);
  final lines = content.split(RegExp(r'\r?\n'));
  final cards = <CsvCard>[];
  var skipped = 0;
  var isFirstDataRow = true;

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final fields = _splitLine(line, separator);
    if (isFirstDataRow && _looksLikeHeader(fields)) {
      isFirstDataRow = false;
      continue;
    }
    isFirstDataRow = false;
    if (fields.length < 2) {
      skipped++;
      continue;
    }
    final front = fields[0].trim();
    final back = fields[1].trim();
    if (front.isEmpty || back.isEmpty) {
      skipped++;
      continue;
    }
    cards.add(CsvCard(front: front, back: back));
  }
  return CsvImportResult(cards: cards, skippedRows: skipped);
}
