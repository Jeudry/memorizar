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
    test('sin IA, los distractores salen del versículo', () {
      final opts = completionOptions(verse, 'pastor', seed: 9);
      final verseWords = studyWords(verse).map((w) => w).toList();
      for (final o in opts) {
        if (sameAnswer(o, 'pastor')) continue;
        expect(verseWords.any((w) => sameAnswer(w, o)), isTrue,
            reason: '$o debería venir del versículo');
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
