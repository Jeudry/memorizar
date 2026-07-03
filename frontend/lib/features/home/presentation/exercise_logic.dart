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

/// Palabras-función agrupadas por CLASE gramatical. Sirven para dar coherencia
/// sintáctica al banco de opciones: si el hueco es una palabra-función (p.ej.
/// un artículo "las"), los distractores deben ser palabras-función de su MISMA
/// clase (otros artículos), nunca palabras de contenido — antes, al puntuar
/// solo por la última letra, un hueco "las" recibía "territorios"/"tierras",
/// un engaño obvio y sin sentido gramatical.
const Set<String> _articleWords = {
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
};
const Set<String> _prepWords = {
  'de', 'del', 'a', 'al', 'en', 'con', 'por', 'para', 'sin', 'sobre', 'tras',
  'hacia', 'desde', 'entre', 'hasta', 'ante', 'bajo', 'contra', 'según',
};
const Set<String> _conjWords = {
  'y', 'e', 'o', 'u', 'ni', 'que', 'pero', 'mas', 'sino', 'porque', 'pues',
  'aunque', 'como', 'si',
};
const Set<String> _pronounWords = {
  'su', 'sus', 'mi', 'mis', 'tu', 'tus', 'se', 'le', 'les', 'lo', 'me', 'te',
  'nos', 'os', 'este', 'esta', 'esto', 'ese', 'esa', 'eso', 'aquel', 'aquella',
};
const List<Set<String>> _functionWordClasses = [
  _articleWords,
  _prepWords,
  _conjWords,
  _pronounWords,
];

/// La clase gramatical de [w] si es una palabra-función, o `null` si es de
/// contenido (sustantivo, verbo, adjetivo…).
Set<String>? _functionWordClass(String w) {
  final lower = w.toLowerCase();
  for (final c in _functionWordClasses) {
    if (c.contains(lower)) return c;
  }
  return null;
}

/// Pool genérico de respaldo para cuando no hay suficientes distractores (todas
/// las palabras ocultas, o la IA aún cargando). Palabras comunes/bíblicas.
const List<String> _fallbackDistractorPool = [
  'cielo', 'tierra', 'luz', 'agua', 'fuego', 'viento', 'monte', 'mar',
  'desierto', 'ciudad', 'templo', 'pueblo', 'rey', 'profeta', 'ángel',
  'justicia', 'pecado', 'gloria', 'pan', 'vino', 'camino', 'verdad', 'vida',
  'muerte', 'noche', 'día', 'palabra', 'mano', 'corazón', 'siervo', 'piedra',
  'río', 'fruto', 'árbol', 'nombre', 'casa', 'monte', 'sol', 'luna',
];

/// Banco de opciones para "Elige la palabra correcta": la palabra correcta +
/// hasta 4 distractores. Prefiere `aiPool` (distractores tramposos de la IA);
/// si no alcanza, rellena con otras palabras del versículo y, como último
/// recurso, con [_fallbackDistractorPool].
List<String> completionOptions(
  String text,
  String target, {
  int seed = 0,
  List<String>? aiPool,
  List<String> exclude = const [],
}) {
  final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
  final cleanTarget = target.replaceAll(cleanRegex, '');
  final excludeClean =
      exclude.map((e) => e.replaceAll(cleanRegex, '')).toList();
  final rng = math.Random(
    seed == 0 ? DateTime.now().microsecondsSinceEpoch : seed,
  );

  bool notExcluded(String w) =>
      !sameAnswer(w, cleanTarget) &&
      !excludeClean.any((e) => sameAnswer(e, w));

  // Hueco de palabra-función (artículo, preposición, conjunción, pronombre):
  // el banco debe ser de la MISMA clase gramatical, nunca palabras de
  // contenido. Así un hueco "las" ofrece otros artículos (los, unas, un…) y no
  // "territorios", que sería un engaño obvio. Se prefiere concordar el número.
  final targetClass = _functionWordClass(cleanTarget);
  if (targetClass != null) {
    final targetPlural = cleanTarget.toLowerCase().endsWith('s');
    int numberRank(String w) => w.endsWith('s') == targetPlural ? 0 : 1;
    final same = targetClass.where(notExcluded).toList()..shuffle(rng);
    same.sort((a, b) => numberRank(a).compareTo(numberRank(b)));
    final picks = <String>[];
    for (final w in same) {
      if (picks.length >= 4) break;
      picks.add(w);
    }
    // Si la clase quedó corta, completa con otras palabras-función.
    if (picks.length < 4) {
      final others = [for (final c in _functionWordClasses) ...c]..shuffle(rng);
      for (final w in others) {
        if (picks.length >= 4) break;
        if (notExcluded(w) && !picks.any((p) => sameAnswer(p, w))) picks.add(w);
      }
    }
    final options = <String>[cleanTarget, ...picks];
    options.shuffle(rng);
    return options;
  }

  // Candidatos: primero el pool de la IA (más tramposos), luego palabras del
  // versículo como respaldo. Dedup, sin la palabra correcta y sin las palabras
  // que son respuesta de OTROS huecos (no mostrar como distractor lo que el
  // usuario debe adivinar en otro hueco). Tampoco palabras-función: en un hueco
  // de contenido, ofrecer "las"/"del"/"por" es un engaño obvio y sin sentido.
  final candidates = <String>[];
  void addCandidate(String word) {
    final clean = word.replaceAll(cleanRegex, '');
    if (clean.length > 2 &&
        _functionWordClass(clean) == null &&
        !sameAnswer(clean, cleanTarget) &&
        !excludeClean.any((e) => sameAnswer(e, clean)) &&
        !candidates.any((c) => sameAnswer(c, clean))) {
      candidates.add(clean);
    }
  }

  for (final word in (aiPool ?? const <String>[])) {
    addCandidate(word);
  }
  for (final word in studyWords(text)) {
    addCandidate(word);
  }
  // Respaldo: si tras excluir quedan pocos distractores (p.ej. cuando casi
  // todas las palabras del versículo son huecos, o mientras la IA aún carga su
  // pool), rellenamos con un pool genérico para que SIEMPRE haya varias
  // opciones jugables y no quede solo la palabra correcta.
  if (candidates.length < 4) {
    for (final word in _fallbackDistractorPool) {
      if (candidates.length >= 6) break;
      addCandidate(word);
    }
  }

  // Coherencia sintáctica: en español la TERMINACIÓN marca tipo y concordancia
  // (-ó verbo pasado, -a femenino, -o masculino, -as/-os plural). Puntuamos cada
  // distractor por cuánto coincide su terminación (y longitud) con el target,
  // para que las opciones encajen gramaticalmente en el hueco y no salga un
  // verbo donde va un sustantivo. Pequeño jitter aleatorio para variar empates.
  final t = cleanTarget.toLowerCase();
  int similarity(String w) {
    final c = w.toLowerCase();
    var s = 0;
    // El ÚLTIMO carácter es la señal fuerte de concordancia/tipo en español.
    if (t.isNotEmpty && c.isNotEmpty && t[t.length - 1] == c[c.length - 1]) {
      s += 3;
      if (t.length >= 2 && c.length >= 2 && t[t.length - 2] == c[c.length - 2]) s += 2;
      if (t.length >= 3 && c.length >= 3 && t[t.length - 3] == c[c.length - 3]) s += 1;
    }
    if ((t.length - c.length).abs() <= 2) s += 1;
    return s;
  }

  final scored = {for (final c in candidates) c: similarity(c) * 10 + rng.nextInt(5)};
  candidates.sort((a, b) => scored[b]!.compareTo(scored[a]!));

  final options = <String>[cleanTarget, ...candidates.take(4)];
  options.shuffle(rng);
  return options;
}

/// Un paso usa micrófono (recitación de voz / niebla) → al omitirlo se
/// reemplaza por selección múltiple; el resto se reemplaza por lectura.
bool isMicSlug(String slug) =>
    slug.contains('voz') || slug.contains('niebla');
