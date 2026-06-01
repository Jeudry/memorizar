/// Reading plans: multi-day curated reading sequences for the Biblia deck.
///
/// Each [ReadingPlan] consists of a list of [PlanDay]s, and each day has a
/// list of [PlanEntry] records that point to a (book, chapter, optional verses)
/// range inside the loaded Bible data (see [AppStore.bibleVerses]).
library;

/// A single chapter/verse range entry inside a [PlanDay].
class PlanEntry {
  final String book;
  final int chapter;

  /// If null, the whole chapter is included.
  final List<int>? verses;

  const PlanEntry({required this.book, required this.chapter, this.verses});
}

/// One day inside a [ReadingPlan].
class PlanDay {
  final int day;
  final String label;
  final List<PlanEntry> entries;

  const PlanDay({
    required this.day,
    required this.label,
    required this.entries,
  });
}

/// A curated multi-day reading plan.
class ReadingPlan {
  final String id;
  final String title;
  final String summary;
  final String icon;
  final List<PlanDay> days;

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.days,
  });

  int get totalDays => days.length;
}

// ---------------------------------------------------------------------------
// Plan builders
// ---------------------------------------------------------------------------

List<PlanDay> _salmosPlan() {
  return List.generate(30, (i) {
    final chapter = i + 1;
    return PlanDay(
      day: chapter,
      label: 'Día $chapter · Salmo $chapter',
      entries: [PlanEntry(book: 'Salmos', chapter: chapter)],
    );
  });
}

List<PlanDay> _romanosPlan() {
  return List.generate(16, (i) {
    final chapter = i + 1;
    return PlanDay(
      day: chapter,
      label: 'Día $chapter · Romanos $chapter',
      entries: [PlanEntry(book: 'Rom', chapter: chapter)],
    );
  });
}

const _sermonMonteDays = <PlanDay>[
  PlanDay(
    day: 1,
    label: 'Día 1 · Bienaventuranzas',
    entries: [PlanEntry(book: 'Mat', chapter: 5, verses: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12])],
  ),
  PlanDay(
    day: 2,
    label: 'Día 2 · Sal y luz',
    entries: [PlanEntry(book: 'Mat', chapter: 5, verses: [13, 14, 15, 16])],
  ),
  PlanDay(
    day: 3,
    label: 'Día 3 · Ley y enseñanza',
    entries: [
      PlanEntry(book: 'Mat', chapter: 5, verses: [17, 18, 19, 20, 21, 22, 23, 24]),
    ],
  ),
  PlanDay(
    day: 4,
    label: 'Día 4 · Amar al enemigo',
    entries: [
      PlanEntry(book: 'Mat', chapter: 5, verses: [38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48]),
    ],
  ),
  PlanDay(
    day: 5,
    label: 'Día 5 · Oración y ayuno',
    entries: [PlanEntry(book: 'Mat', chapter: 6, verses: [5, 6, 7, 8, 9, 10, 11, 12, 13])],
  ),
  PlanDay(
    day: 6,
    label: 'Día 6 · Tesoro y afán',
    entries: [
      PlanEntry(book: 'Mat', chapter: 6, verses: [19, 20, 21, 24, 25, 26, 33, 34]),
    ],
  ),
  PlanDay(
    day: 7,
    label: 'Día 7 · Pedid y la roca',
    entries: [PlanEntry(book: 'Mat', chapter: 7, verses: [7, 8, 12, 13, 14, 24, 25])],
  ),
];

const _frutoEspirituDays = <PlanDay>[
  PlanDay(day: 1, label: 'Día 1 · Amor', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 2, label: 'Día 2 · Gozo', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 3, label: 'Día 3 · Paz', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 4, label: 'Día 4 · Paciencia', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 5, label: 'Día 5 · Benignidad', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 6, label: 'Día 6 · Bondad', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 7, label: 'Día 7 · Fe', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [22])]),
  PlanDay(day: 8, label: 'Día 8 · Mansedumbre', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [23])]),
  PlanDay(day: 9, label: 'Día 9 · Templanza', entries: [PlanEntry(book: 'Gál', chapter: 5, verses: [23])]),
];

const _parabolasDays = <PlanDay>[
  PlanDay(day: 1, label: 'Día 1 · El sembrador', entries: [PlanEntry(book: 'Mat', chapter: 13, verses: [3, 4, 5, 6, 7, 8, 9])]),
  PlanDay(day: 2, label: 'Día 2 · Trigo y cizaña', entries: [PlanEntry(book: 'Mat', chapter: 13, verses: [24, 25, 26, 27, 28, 29, 30])]),
  PlanDay(day: 3, label: 'Día 3 · Grano de mostaza', entries: [PlanEntry(book: 'Mat', chapter: 13, verses: [31, 32])]),
  PlanDay(day: 4, label: 'Día 4 · Tesoro escondido', entries: [PlanEntry(book: 'Mat', chapter: 13, verses: [44, 45, 46])]),
  PlanDay(day: 5, label: 'Día 5 · La red', entries: [PlanEntry(book: 'Mat', chapter: 13, verses: [47, 48, 49, 50])]),
  PlanDay(day: 6, label: 'Día 6 · Siervo despiadado', entries: [PlanEntry(book: 'Mat', chapter: 18, verses: [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35])]),
  PlanDay(day: 7, label: 'Día 7 · Obreros de la viña', entries: [PlanEntry(book: 'Mat', chapter: 20, verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])]),
  PlanDay(day: 8, label: 'Día 8 · Las diez vírgenes', entries: [PlanEntry(book: 'Mat', chapter: 25, verses: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])]),
  PlanDay(day: 9, label: 'Día 9 · Los talentos', entries: [PlanEntry(book: 'Mat', chapter: 25, verses: [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30])]),
  PlanDay(day: 10, label: 'Día 10 · Buen samaritano', entries: [PlanEntry(book: 'Luc', chapter: 10, verses: [30, 31, 32, 33, 34, 35, 36, 37])]),
  PlanDay(day: 11, label: 'Día 11 · Hijo pródigo', entries: [PlanEntry(book: 'Luc', chapter: 15, verses: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])]),
  PlanDay(day: 12, label: 'Día 12 · Rico y Lázaro', entries: [PlanEntry(book: 'Luc', chapter: 16, verses: [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31])]),
];

const _davidDays = <PlanDay>[
  PlanDay(day: 1, label: 'Día 1 · Ungido', entries: [PlanEntry(book: '1Sam', chapter: 16)]),
  PlanDay(day: 2, label: 'Día 2 · David y Goliat', entries: [PlanEntry(book: '1Sam', chapter: 17)]),
  PlanDay(day: 3, label: 'Día 3 · Jonatán', entries: [PlanEntry(book: '1Sam', chapter: 18)]),
  PlanDay(day: 4, label: 'Día 4 · Huyendo de Saúl', entries: [PlanEntry(book: '1Sam', chapter: 19)]),
  PlanDay(day: 5, label: 'Día 5 · Cueva de Adulam', entries: [PlanEntry(book: '1Sam', chapter: 22)]),
  PlanDay(day: 6, label: 'Día 6 · Perdona a Saúl', entries: [PlanEntry(book: '1Sam', chapter: 24)]),
  PlanDay(day: 7, label: 'Día 7 · Muerte de Saúl', entries: [PlanEntry(book: '1Sam', chapter: 31)]),
  PlanDay(day: 8, label: 'Día 8 · Rey de Judá', entries: [PlanEntry(book: '2Sam', chapter: 2)]),
  PlanDay(day: 9, label: 'Día 9 · Rey de Israel', entries: [PlanEntry(book: '2Sam', chapter: 5)]),
  PlanDay(day: 10, label: 'Día 10 · El arca', entries: [PlanEntry(book: '2Sam', chapter: 6)]),
  PlanDay(day: 11, label: 'Día 11 · Pacto', entries: [PlanEntry(book: '2Sam', chapter: 7)]),
  PlanDay(day: 12, label: 'Día 12 · David y Betsabé', entries: [PlanEntry(book: '2Sam', chapter: 11)]),
  PlanDay(day: 13, label: 'Día 13 · Arrepentimiento', entries: [PlanEntry(book: 'Salmos', chapter: 51)]),
  PlanDay(day: 14, label: 'Día 14 · Últimas palabras', entries: [PlanEntry(book: '2Sam', chapter: 23)]),
];

const _promesasDays = <PlanDay>[
  PlanDay(day: 1, label: 'Día 1 · Pacto con Noé', entries: [PlanEntry(book: 'Gén', chapter: 9, verses: [11, 12, 13, 14, 15, 16])]),
  PlanDay(day: 2, label: 'Día 2 · Promesa a Abram', entries: [PlanEntry(book: 'Gén', chapter: 12, verses: [1, 2, 3])]),
  PlanDay(day: 3, label: 'Día 3 · Descendencia', entries: [PlanEntry(book: 'Gén', chapter: 15, verses: [1, 5, 6])]),
  PlanDay(day: 4, label: 'Día 4 · Bendición', entries: [PlanEntry(book: 'Núm', chapter: 6, verses: [24, 25, 26])]),
  PlanDay(day: 5, label: 'Día 5 · Esfuérzate', entries: [PlanEntry(book: 'Jos', chapter: 1, verses: [9])]),
  PlanDay(day: 6, label: 'Día 6 · Pastor', entries: [PlanEntry(book: 'Salmos', chapter: 23)]),
  PlanDay(day: 7, label: 'Día 7 · Refugio', entries: [PlanEntry(book: 'Salmos', chapter: 91, verses: [1, 2, 3, 4, 5, 6, 7])]),
  PlanDay(day: 8, label: 'Día 8 · Sanidad', entries: [PlanEntry(book: 'Salmos', chapter: 103, verses: [1, 2, 3, 4, 5])]),
  PlanDay(day: 9, label: 'Día 9 · Confianza', entries: [PlanEntry(book: 'Prov', chapter: 3, verses: [5, 6])]),
  PlanDay(day: 10, label: 'Día 10 · Renuevan fuerzas', entries: [PlanEntry(book: 'Isa', chapter: 40, verses: [29, 30, 31])]),
  PlanDay(day: 11, label: 'Día 11 · No temas', entries: [PlanEntry(book: 'Isa', chapter: 41, verses: [10])]),
  PlanDay(day: 12, label: 'Día 12 · Cosa nueva', entries: [PlanEntry(book: 'Isa', chapter: 43, verses: [1, 2, 18, 19])]),
  PlanDay(day: 13, label: 'Día 13 · Pensamientos', entries: [PlanEntry(book: 'Jer', chapter: 29, verses: [11, 12, 13])]),
  PlanDay(day: 14, label: 'Día 14 · Vida abundante', entries: [PlanEntry(book: 'Juan', chapter: 10, verses: [10, 11, 27, 28])]),
  PlanDay(day: 15, label: 'Día 15 · Paz', entries: [PlanEntry(book: 'Juan', chapter: 14, verses: [27])]),
  PlanDay(day: 16, label: 'Día 16 · Todo ayuda a bien', entries: [PlanEntry(book: 'Rom', chapter: 8, verses: [28, 31, 37, 38, 39])]),
  PlanDay(day: 17, label: 'Día 17 · No tentación', entries: [PlanEntry(book: '1Cor', chapter: 10, verses: [13])]),
  PlanDay(day: 18, label: 'Día 18 · Fortalece', entries: [PlanEntry(book: 'Fil', chapter: 4, verses: [6, 7, 13, 19])]),
  PlanDay(day: 19, label: 'Día 19 · Trono de gracia', entries: [PlanEntry(book: 'Heb', chapter: 4, verses: [14, 15, 16])]),
  PlanDay(day: 20, label: 'Día 20 · Misericordias', entries: [PlanEntry(book: 'Lam', chapter: 3, verses: [22, 23, 24, 25, 26])]),
  PlanDay(day: 21, label: 'Día 21 · Cielo nuevo', entries: [PlanEntry(book: 'Apoc', chapter: 21, verses: [1, 2, 3, 4])]),
];

const _proverbiosDays = <PlanDay>[
  PlanDay(day: 1, label: 'Día 1 · Sabiduría', entries: [PlanEntry(book: 'Prov', chapter: 1)]),
  PlanDay(day: 2, label: 'Día 2 · Beneficios', entries: [PlanEntry(book: 'Prov', chapter: 2)]),
  PlanDay(day: 3, label: 'Día 3 · Confianza', entries: [PlanEntry(book: 'Prov', chapter: 3)]),
  PlanDay(day: 4, label: 'Día 4 · Guarda tu corazón', entries: [PlanEntry(book: 'Prov', chapter: 4)]),
  PlanDay(day: 5, label: 'Día 5 · La pereza', entries: [PlanEntry(book: 'Prov', chapter: 6)]),
  PlanDay(day: 6, label: 'Día 6 · La llamada', entries: [PlanEntry(book: 'Prov', chapter: 8)]),
  PlanDay(day: 7, label: 'Día 7 · Mujer virtuosa', entries: [PlanEntry(book: 'Prov', chapter: 31)]),
];

final List<ReadingPlan> readingPlans = [
  ReadingPlan(
    id: 'salmos-30',
    title: 'Salmos en 30 días',
    summary: 'Un salmo por día para empezar la mañana en oración.',
    icon: '🎵',
    days: _salmosPlan(),
  ),
  const ReadingPlan(
    id: 'parabolas',
    title: 'Las parábolas de Jesús',
    summary: 'Doce parábolas memorables del Maestro.',
    icon: '🌱',
    days: _parabolasDays,
  ),
  const ReadingPlan(
    id: 'vida-david',
    title: 'Vida de David',
    summary: 'Del pastor al rey: 14 estampas de su historia.',
    icon: '👑',
    days: _davidDays,
  ),
  const ReadingPlan(
    id: 'fruto-espiritu',
    title: 'Fruto del Espíritu',
    summary: 'Nueve días, una virtud por día (Gálatas 5).',
    icon: '🍇',
    days: _frutoEspirituDays,
  ),
  const ReadingPlan(
    id: 'sermon-monte',
    title: 'Sermón del Monte',
    summary: 'Siete pasos por Mateo 5–7.',
    icon: '⛰️',
    days: _sermonMonteDays,
  ),
  const ReadingPlan(
    id: 'promesas-dios',
    title: 'Promesas de Dios',
    summary: '21 promesas para fortalecer la fe.',
    icon: '🌈',
    days: _promesasDays,
  ),
  ReadingPlan(
    id: 'romanos-16',
    title: 'Romanos en 16 días',
    summary: 'Un capítulo por día de la carta a los romanos.',
    icon: '📜',
    days: _romanosPlan(),
  ),
  const ReadingPlan(
    id: 'proverbios-7',
    title: 'Proverbios en 7 días',
    summary: 'Una semana de sabiduría práctica.',
    icon: '🦉',
    days: _proverbiosDays,
  ),
];

ReadingPlan? findReadingPlan(String id) {
  for (final plan in readingPlans) {
    if (plan.id == id) return plan;
  }
  return null;
}
