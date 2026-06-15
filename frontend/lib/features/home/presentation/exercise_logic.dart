import 'dart:math' as math;

/// Lógica pura (sin UI ni estado) del motor de ejercicios. Extraída de las
/// pantallas para poder probarla en aislamiento. Los wrappers privados en
/// `biblia_screen.dart` / `ui_screens.dart` delegan aquí.

/// Parte un texto en palabras, normalizando comillas y espacios. Si queda
/// vacío devuelve un fallback estable (útil para no romper la UI).
List<String> studyWords(String text) {
  final cleaned = text
      .replaceAll(RegExp(r'[“”"]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return const ['Jehová', 'es', 'mi', 'pastor'];
  return cleaned.split(' ');
}

String firstWords(String text, int count) =>
    studyWords(text).take(count).join(' ');

/// Comparación tolerante: ignora mayúsculas, acentos y puntuación.
bool sameAnswer(String a, String b) {
  String normalize(String value) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var text = value.toLowerCase();
    for (final entry in accents.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(RegExp(r'[^a-z]'), '');
  }

  return normalize(a) == normalize(b);
}

/// Una palabra "objetivo" representativa del versículo según el nivel.
String targetWord(String text, {required int level}) {
  final words = studyWords(text)
      .where(
        (word) =>
            word.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '').length > 3,
      )
      .toList();
  if (words.isEmpty) return studyWords(text).first;
  final offset = switch (level) {
    1 => 0,
    2 => words.length ~/ 2,
    _ => words.length - 1,
  };
  return words[offset.clamp(0, words.length - 1)];
}

/// Palabras a rellenar (huecos) según el nivel: N1 pocas, N2 ~65%, N3 todas.
/// `seed` permite resultados deterministas (0 = aleatorio real).
List<String> completionTargets(String text,
    {required int level, int seed = 0}) {
  final words = studyWords(text);
  if (words.isEmpty) return [];
  if (level >= 3) return [...words];
  final candidateIndexes = <int>[];
  for (var i = 0; i < words.length; i++) {
    final clean = words[i].replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '');
    if (clean.length > 2) candidateIndexes.add(i);
  }
  final sourceIndexes = candidateIndexes.isEmpty
      ? List<int>.generate(words.length, (i) => i)
      : candidateIndexes;
  if (sourceIndexes.isEmpty) return [];
  final targetCount = switch (level) {
    1 => 3,
    2 => (sourceIndexes.length * 0.65).round(),
    _ => sourceIndexes.length,
  }.clamp(1, sourceIndexes.length).toInt();
  final rng = math.Random(seed == 0 ? null : seed);
  final pickPool = List<int>.from(sourceIndexes)..shuffle(rng);
  final picked = <int>{};
  for (final idx in pickPool) {
    final word = words[idx];
    final alreadyPicked =
        picked.any((existing) => sameAnswer(words[existing], word));
    if (alreadyPicked) continue;
    picked.add(idx);
    if (picked.length >= targetCount) break;
  }
  // Devolver en orden del texto (mapeando a la primera ocurrencia).
  final ordered = picked.map((idx) {
    final word = words[idx];
    return words.indexWhere((w) => sameAnswer(w, word));
  }).toList()
    ..sort();
  return ordered.map((i) => words[i]).toList();
}

/// Banco de opciones para "Elige la palabra correcta": la palabra correcta +
/// hasta 4 distractores. Prefiere `aiPool` (distractores tramposos de la IA);
/// si no alcanza, rellena con otras palabras del versículo.
List<String> completionOptions(
  String text,
  String target, {
  int seed = 0,
  List<String>? aiPool,
}) {
  final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
  final cleanTarget = target.replaceAll(cleanRegex, '');
  final rng = math.Random(
    seed == 0 ? DateTime.now().microsecondsSinceEpoch : seed,
  );

  final versePool = <String>[];
  for (final word in studyWords(text)) {
    final clean = word.replaceAll(cleanRegex, '');
    if (clean.length > 3 &&
        !sameAnswer(clean, cleanTarget) &&
        !versePool.any((p) => sameAnswer(p, clean))) {
      versePool.add(clean);
    }
  }

  final distractors = <String>[];
  if (aiPool != null && aiPool.isNotEmpty) {
    final cleaned = <String>[];
    for (final word in aiPool) {
      final clean = word.replaceAll(cleanRegex, '');
      if (clean.length > 2 &&
          !sameAnswer(clean, cleanTarget) &&
          !cleaned.any((p) => sameAnswer(p, clean))) {
        cleaned.add(clean);
      }
    }
    cleaned.shuffle(rng);
    distractors.addAll(cleaned.take(4));
  }
  if (distractors.length < 4) {
    final pad = [...versePool]..shuffle(rng);
    for (final word in pad) {
      if (distractors.length >= 4) break;
      if (!distractors.any((d) => sameAnswer(d, word))) distractors.add(word);
    }
  }

  final options = <String>[cleanTarget, ...distractors.take(4)];
  options.shuffle(rng);
  return options;
}

/// Un paso usa micrófono (recitación de voz / niebla) → al omitirlo se
/// reemplaza por selección múltiple; el resto se reemplaza por lectura.
bool isMicSlug(String slug) =>
    slug.contains('voz') || slug.contains('niebla');
