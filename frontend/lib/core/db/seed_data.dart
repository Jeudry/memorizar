import 'package:drift/drift.dart';
import 'package:memorizar/core/db/app_database.dart';

Future<void> seedDatabase(AppDatabase db) async {
  final existing = await db.getAllDecks();
  if (existing.isNotEmpty) return; // already seeded

  // Deck: Biblia
  await db.upsertDeck(DecksCompanion.insert(
    id: 'bible',
    name: 'Biblia',
    description: 'Versículos del Antiguo y Nuevo Testamento',
    type: 'bible',
    accentColorIndex: const Value(0),
    emoji: const Value('✝️'),
  ));

  final bibleItems = [
    ('b1', 'Juan 3:16', 'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.', 'Juan', 3, 16),
    ('b2', 'Salmos 23:1', 'El Señor es mi pastor; nada me faltará.', 'Salmos', 23, 1),
    ('b3', 'Filipenses 4:13', 'Todo lo puedo en Cristo que me fortalece.', 'Filipenses', 4, 13),
    ('b4', 'Romanos 8:28', 'Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien, esto es, a los que conforme a su propósito son llamados.', 'Romanos', 8, 28),
    ('b5', 'Jeremías 29:11', 'Porque yo sé los pensamientos que tengo acerca de vosotros, dice Jehovah, pensamientos de paz, y no de mal, para daros el fin que esperáis.', 'Jeremías', 29, 11),
    ('b6', 'Isaías 40:31', 'Pero los que esperan en Jehovah tendrán nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; caminarán, y no se fatigarán.', 'Isaías', 40, 31),
    ('b7', 'Proverbios 3:5-6', 'Confía en Jehovah con todo tu corazón, y no te apoyes en tu propia prudencia. Reconócelo en todos tus caminos, y él enderezará tus veredas.', 'Proverbios', 3, 5),
    ('b8', 'Mateo 6:33', 'Mas buscad primeramente el reino de Dios y su justicia, y todas estas cosas os serán añadidas.', 'Mateo', 6, 33),
    ('b9', '1 Corintios 13:4-5', 'El amor es sufrido, es benigno; el amor no tiene envidia, el amor no es jactancioso, no se envanece; no hace nada indebido, no busca lo suyo, no se irrita, no guarda rencor.', '1 Corintios', 13, 4),
    ('b10', 'Josué 1:9', 'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehovah tu Dios estará contigo en dondequiera que vayas.', 'Josué', 1, 9),
    ('b11', 'Génesis 1:1', 'En el principio creó Dios los cielos y la tierra.', 'Génesis', 1, 1),
    ('b12', 'Apocalipsis 21:4', 'Enjugará Dios toda lágrima de los ojos de ellos; y ya no habrá muerte, ni habrá más llanto, ni clamor, ni dolor; porque las primeras cosas pasaron.', 'Apocalipsis', 21, 4),
  ];

  for (final item in bibleItems) {
    await db.upsertItem(ItemsCompanion.insert(
      id: item.$1,
      deckId: 'bible',
      front: item.$2,
      back: item.$3,
      book: Value(item.$4),
      chapter: Value(item.$5),
      verse: Value(item.$6),
    ));
  }

  // Deck: Inglés B2
  await db.upsertDeck(DecksCompanion.insert(
    id: 'english',
    name: 'Inglés B2',
    description: 'Vocabulario esencial nivel intermedio-avanzado',
    type: 'language',
    accentColorIndex: const Value(2),
    emoji: const Value('🇺🇸'),
  ));

  final englishItems = [
    ('e1', 'Ambiguous', 'Ambiguo — que puede interpretarse de más de una manera'),
    ('e2', 'Eloquent', 'Elocuente — que se expresa con claridad y persuasión'),
    ('e3', 'Tenacious', 'Tenaz — que persiste a pesar de la dificultad'),
    ('e4', 'Diligent', 'Diligente — que trabaja con cuidado y persistencia'),
    ('e5', 'Profound', 'Profundo — que tiene gran profundidad de conocimiento'),
    ('e6', 'Subtle', 'Sutil — que es difícil de percibir o entender'),
    ('e7', 'Resilient', 'Resiliente — que se recupera rápidamente de dificultades'),
    ('e8', 'Concise', 'Conciso — que expresa mucho con pocas palabras'),
  ];

  for (final item in englishItems) {
    await db.upsertItem(ItemsCompanion.insert(
      id: item.$1,
      deckId: 'english',
      front: item.$2,
      back: item.$3,
    ));
  }

  // Deck: Capitales
  await db.upsertDeck(DecksCompanion.insert(
    id: 'capitals',
    name: 'Capitales del mundo',
    description: 'Capitales de los 195 países reconocidos',
    type: 'general',
    accentColorIndex: const Value(4),
    emoji: const Value('🌍'),
  ));

  final capitalsItems = [
    ('c1', '¿Capital de Francia?', 'París'),
    ('c2', '¿Capital de Japón?', 'Tokio'),
    ('c3', '¿Capital de Brasil?', 'Brasilia'),
    ('c4', '¿Capital de Australia?', 'Canberra'),
    ('c5', '¿Capital de Canadá?', 'Ottawa'),
    ('c6', '¿Capital de Sudáfrica?', 'Pretoria (ejecutiva), Ciudad del Cabo (legislativa), Bloemfontein (judicial)'),
    ('c7', '¿Capital de Argentina?', 'Buenos Aires'),
    ('c8', '¿Capital de India?', 'Nueva Delhi'),
    ('c9', '¿Capital de México?', 'Ciudad de México'),
    ('c10', '¿Capital de Nueva Zelanda?', 'Wellington'),
  ];

  for (final item in capitalsItems) {
    await db.upsertItem(ItemsCompanion.insert(
      id: item.$1,
      deckId: 'capitals',
      front: item.$2,
      back: item.$3,
    ));
  }
}
