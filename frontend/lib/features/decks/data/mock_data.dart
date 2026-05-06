import 'models/deck.dart';
import 'models/item.dart';

final mockDecks = [
  Deck(
    id: 'bible',
    name: 'Biblia',
    description: 'Versículos del Antiguo y Nuevo Testamento',
    type: DeckType.bible,
    accentColorIndex: 0,
    totalItems: 12,
    dueToday: 5,
    learned: 3,
    createdAt: _epoch,
    emoji: '✝️',
  ),
  Deck(
    id: 'english',
    name: 'Inglés B2',
    description: 'Vocabulario esencial nivel intermedio-avanzado',
    type: DeckType.language,
    accentColorIndex: 2,
    totalItems: 8,
    dueToday: 2,
    learned: 1,
    createdAt: _epoch,
    emoji: '🇺🇸',
  ),
  Deck(
    id: 'capitals',
    name: 'Capitales del mundo',
    description: 'Capitales de los 195 países reconocidos',
    type: DeckType.general,
    accentColorIndex: 4,
    totalItems: 10,
    dueToday: 0,
    learned: 0,
    createdAt: _epoch,
    emoji: '🌍',
  ),
];

final _epoch = DateTime.utc(2026, 1, 1);

final mockBibleItems = [
  const Item(
    id: 'b1',
    deckId: 'bible',
    front: 'Juan 3:16',
    back:
        'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
    book: 'Juan',
    chapter: 3,
    verse: 16,
  ),
  const Item(
    id: 'b2',
    deckId: 'bible',
    front: 'Salmos 23:1',
    back: 'El Señor es mi pastor; nada me faltará.',
    book: 'Salmos',
    chapter: 23,
    verse: 1,
  ),
  const Item(
    id: 'b3',
    deckId: 'bible',
    front: 'Filipenses 4:13',
    back: 'Todo lo puedo en Cristo que me fortalece.',
    book: 'Filipenses',
    chapter: 4,
    verse: 13,
  ),
  const Item(
    id: 'b4',
    deckId: 'bible',
    front: 'Romanos 8:28',
    back:
        'Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien, esto es, a los que conforme a su propósito son llamados.',
    book: 'Romanos',
    chapter: 8,
    verse: 28,
  ),
  const Item(
    id: 'b5',
    deckId: 'bible',
    front: 'Jeremías 29:11',
    back:
        'Porque yo sé los pensamientos que tengo acerca de vosotros, dice Jehová, pensamientos de paz, y no de mal, para daros el fin que esperáis.',
    book: 'Jeremías',
    chapter: 29,
    verse: 11,
  ),
  const Item(
    id: 'b6',
    deckId: 'bible',
    front: 'Isaías 40:31',
    back:
        'Pero los que esperan en Jehová tendrán nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; caminarán, y no se fatigarán.',
    book: 'Isaías',
    chapter: 40,
    verse: 31,
  ),
  const Item(
    id: 'b7',
    deckId: 'bible',
    front: 'Proverbios 3:5-6',
    back:
        'Confía en Jehová con todo tu corazón, y no te apoyes en tu propia prudencia. Reconócelo en todos tus caminos, y él enderezará tus veredas.',
    book: 'Proverbios',
    chapter: 3,
    verse: 5,
  ),
  const Item(
    id: 'b8',
    deckId: 'bible',
    front: 'Mateo 6:33',
    back:
        'Mas buscad primeramente el reino de Dios y su justicia, y todas estas cosas os serán añadidas.',
    book: 'Mateo',
    chapter: 6,
    verse: 33,
  ),
  const Item(
    id: 'b9',
    deckId: 'bible',
    front: '1 Corintios 13:4-5',
    back:
        'El amor es sufrido, es benigno; el amor no tiene envidia, el amor no es jactancioso, no se envanece; no hace nada indebido, no busca lo suyo, no se irrita, no guarda rencor.',
    book: '1 Corintios',
    chapter: 13,
    verse: 4,
  ),
  const Item(
    id: 'b10',
    deckId: 'bible',
    front: 'Josué 1:9',
    back:
        'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehová tu Dios estará contigo en dondequiera que vayas.',
    book: 'Josué',
    chapter: 1,
    verse: 9,
  ),
  const Item(
    id: 'b11',
    deckId: 'bible',
    front: 'Génesis 1:1',
    back: 'En el principio creó Dios los cielos y la tierra.',
    book: 'Génesis',
    chapter: 1,
    verse: 1,
  ),
  const Item(
    id: 'b12',
    deckId: 'bible',
    front: 'Apocalipsis 21:4',
    back:
        'Enjugará Dios toda lágrima de los ojos de ellos; y ya no habrá muerte, ni habrá más llanto, ni clamor, ni dolor; porque las primeras cosas pasaron.',
    book: 'Apocalipsis',
    chapter: 21,
    verse: 4,
  ),
];

final mockEnglishItems = [
  const Item(id: 'e1', deckId: 'english', front: 'Ambiguous', back: 'Ambiguo — que puede interpretarse de más de una manera'),
  const Item(id: 'e2', deckId: 'english', front: 'Eloquent', back: 'Elocuente — que se expresa con claridad y persuasión'),
  const Item(id: 'e3', deckId: 'english', front: 'Tenacious', back: 'Tenaz — que persiste a pesar de la dificultad'),
  const Item(id: 'e4', deckId: 'english', front: 'Diligent', back: 'Diligente — que trabaja con cuidado y persistencia'),
  const Item(id: 'e5', deckId: 'english', front: 'Profound', back: 'Profundo — que tiene gran profundidad de conocimiento'),
  const Item(id: 'e6', deckId: 'english', front: 'Subtle', back: 'Sutil — que es difícil de percibir o entender'),
  const Item(id: 'e7', deckId: 'english', front: 'Resilient', back: 'Resiliente — que se recupera rápidamente de dificultades'),
  const Item(id: 'e8', deckId: 'english', front: 'Concise', back: 'Conciso — que expresa mucho con pocas palabras'),
];

final mockCapitalsItems = [
  const Item(id: 'c1', deckId: 'capitals', front: '¿Capital de Francia?', back: 'París'),
  const Item(id: 'c2', deckId: 'capitals', front: '¿Capital de Japón?', back: 'Tokio'),
  const Item(id: 'c3', deckId: 'capitals', front: '¿Capital de Brasil?', back: 'Brasilia'),
  const Item(id: 'c4', deckId: 'capitals', front: '¿Capital de Australia?', back: 'Canberra'),
  const Item(id: 'c5', deckId: 'capitals', front: '¿Capital de Canadá?', back: 'Ottawa'),
  const Item(id: 'c6', deckId: 'capitals', front: '¿Capital de Sudáfrica?', back: 'Pretoria (ejecutiva), Ciudad del Cabo (legislativa), Bloemfontein (judicial)'),
  const Item(id: 'c7', deckId: 'capitals', front: '¿Capital de Argentina?', back: 'Buenos Aires'),
  const Item(id: 'c8', deckId: 'capitals', front: '¿Capital de India?', back: 'Nueva Delhi'),
  const Item(id: 'c9', deckId: 'capitals', front: '¿Capital de México?', back: 'Ciudad de México'),
  const Item(id: 'c10', deckId: 'capitals', front: '¿Capital de Nueva Zelanda?', back: 'Wellington'),
];

Map<String, List<Item>> get allMockItems => {
  'bible': mockBibleItems,
  'english': mockEnglishItems,
  'capitals': mockCapitalsItems,
};
