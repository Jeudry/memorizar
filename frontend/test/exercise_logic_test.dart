import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/presentation/exercise_logic.dart';

/// Lógica pura del motor de ejercicios (sin UI): partir palabras, comparación
/// tolerante, huecos del completar, banco de distractores y clasificación de
/// pasos de micrófono (F2/F3/F4).
void main() {
  group('studyWords / firstWords', () {
    test('separa palabras y quita comillas', () {
      expect(studyWords('“Jehová  es mi   pastor”'),
          ['Jehová', 'es', 'mi', 'pastor']);
    });
    test('texto vacío devuelve fallback estable', () {
      expect(studyWords('   '), ['Jehová', 'es', 'mi', 'pastor']);
    });
    test('firstWords toma las primeras N', () {
      expect(firstWords('uno dos tres cuatro', 2), 'uno dos');
    });
  });

  group('sameAnswer', () {
    test('ignora mayúsculas, acentos y puntuación', () {
      expect(sameAnswer('Jehová', 'jehova'), isTrue);
      expect(sameAnswer('¡Pastor!', 'pastor'), isTrue);
      expect(sameAnswer('niño', 'nino'), isTrue);
    });
    test('distingue palabras distintas', () {
      expect(sameAnswer('pastor', 'rebaño'), isFalse);
    });
  });

  group('completionTargets', () {
    const verse = 'Jehová es mi pastor nada me faltará';
    test('N3 esconde TODAS las palabras', () {
      expect(completionTargets(verse, level: 3), studyWords(verse));
    });
    test('N1 elige 3 huecos, en orden del texto', () {
      final targets = completionTargets(verse, level: 1, seed: 7);
      expect(targets, hasLength(3));
      // En orden de aparición.
      final positions =
          targets.map((t) => studyWords(verse).indexOf(t)).toList();
      final sorted = [...positions]..sort();
      expect(positions, sorted);
    });
    test('con la misma semilla es determinista', () {
      expect(completionTargets(verse, level: 2, seed: 42),
          completionTargets(verse, level: 2, seed: 42));
    });
  });

  group('completionOptions (banco de distractores)', () {
    const verse = 'Jehová es mi pastor nada me faltará';
    test('siempre incluye la palabra correcta', () {
      final opts = completionOptions(verse, 'pastor', seed: 3);
      expect(opts.any((o) => sameAnswer(o, 'pastor')), isTrue);
    });
    test('no repite la palabra correcta como distractor', () {
      final opts = completionOptions(verse, 'pastor', seed: 3);
      final correctCount =
          opts.where((o) => sameAnswer(o, 'pastor')).length;
      expect(correctCount, 1);
    });
    test('prefiere el pool de la IA cuando está disponible', () {
      final opts = completionOptions(
        verse,
        'pastor',
        seed: 5,
        aiPool: ['oveja', 'rebaño', 'cordero', 'redil'],
      );
      // Al menos un distractor sale del pool de IA (no del versículo).
      expect(opts.any((o) => o == 'oveja' || o == 'rebaño' || o == 'cordero'),
          isTrue);
    });
    test('sin IA, con suficientes palabras los distractores salen del versículo', () {
      // Versículo con >=5 palabras de contenido para que no entre el banco de
      // respaldo genérico (que sí se usa cuando quedan pocas).
      const longVerse = 'En el principio creó Dios los cielos y la tierra hermosa';
      final opts = completionOptions(longVerse, 'cielos', seed: 9);
      final verseWords = studyWords(longVerse);
      for (final o in opts) {
        if (sameAnswer(o, 'cielos')) continue;
        expect(verseWords.any((w) => sameAnswer(w, o)), isTrue,
            reason: '$o debería venir del versículo');
      }
    });
    test('sin IA y con pocas palabras, igual ofrece varias opciones', () {
      // 'Jehová es mi pastor' deja pocos candidatos → se rellena con el banco
      // de respaldo para no dejar una sola opción.
      final opts = completionOptions('Jehová es mi pastor', 'pastor', seed: 9);
      expect(opts.length, greaterThanOrEqualTo(3));
      expect(opts.where((o) => sameAnswer(o, 'pastor')).length, 1);
    });
    test('coherencia: prefiere distractores con la misma terminación que el target', () {
      // target "creó" (verbo, termina en -ó). El pool mezcla verbos -ó con
      // sustantivos/adjetivos; deben ganar los -ó por concordancia.
      const text = 'En el principio creó Dios el cielo y la tierra';
      const pool = ['formó', 'llamó', 'mostró', 'mesa', 'azul', 'silla', 'rojo', 'árbol'];
      final accentVerbs = {'formó', 'llamó', 'mostró'};
      // Varias semillas: en su mayoría los distractores deben terminar en -ó.
      var oMatchTotal = 0;
      var distractorTotal = 0;
      for (var seed = 1; seed <= 6; seed++) {
        final opts = completionOptions(text, 'creó', seed: seed, aiPool: pool);
        for (final o in opts) {
          if (sameAnswer(o, 'creó')) continue;
          distractorTotal++;
          if (accentVerbs.contains(o)) oMatchTotal++;
        }
      }
      // La mayoría de los distractores elegidos deben ser los verbos -ó.
      expect(oMatchTotal / distractorTotal, greaterThan(0.6),
          reason: 'los distractores deberían concordar en terminación con "creó"');
    });
    test('hueco de palabra-función NO ofrece palabras de contenido', () {
      // Reproduce el bug: para el hueco "las" salía "territorios"/"tierras".
      const verse = 'Y los ha reunido de las tierras del oriente';
      final opts = completionOptions(verse, 'las', seed: 4);
      expect(opts.where((o) => sameAnswer(o, 'las')).length, 1);
      for (final content in ['tierras', 'oriente', 'reunido']) {
        expect(opts.any((o) => sameAnswer(o, content)), isFalse,
            reason: 'un hueco de artículo no debería ofrecer "$content"');
      }
    });
    test('hueco de contenido NO ofrece palabras-función como distractor', () {
      const verse = 'Y los ha reunido de las tierras del oriente poderoso';
      final opts = completionOptions(verse, 'tierras', seed: 4);
      for (final fn in ['los', 'las', 'del', 'de']) {
        expect(opts.any((o) => sameAnswer(o, fn)), isFalse,
            reason: 'un hueco de contenido no debería ofrecer "$fn"');
      }
    });
  });

  group('isMicSlug', () {
    test('voz y niebla usan micrófono', () {
      expect(isMicSlug('03-leer-voz'), isTrue);
      expect(isMicSlug('02-niebla-n1'), isTrue);
      expect(isMicSlug('14-voz-final'), isTrue);
    });
    test('completar/lectura/quiz no usan micrófono', () {
      expect(isMicSlug('06-completar-n1'), isFalse);
      expect(isMicSlug('00-solo-lectura'), isFalse);
      expect(isMicSlug('09-quiz'), isFalse);
    });
  });
}
