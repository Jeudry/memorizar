import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/ai_quiz_models.dart';
import 'package:frontend/core/services/local_llm_service.dart';

/// Garantía de código: el fallback de palabras intrusas SIEMPRE produce un
/// ejercicio jugable (alterado ≠ original, exactamente `level` intrusos nuevos),
/// pase lo que pase con la IA. Y la validación rechaza el caso roto.
void main() {
  const verses = [
    'En el principio creó Dios el cielo y la tierra.',
    'Todo lo puedo en Cristo que me fortalece.',
    'El Señor es mi pastor, nada me faltará.',
    'Porque de tal manera amó Dios al mundo.',
    'La luz en las tinieblas resplandece.',
  ];

  group('buildFallbackIntruderVerse', () {
    test('siempre genera un ejercicio válido para niveles 1-3 y varias semillas', () {
      for (final verse in verses) {
        for (var level = 1; level <= 3; level++) {
          for (var seed = 0; seed < 8; seed++) {
            final set = LocalLlmService.buildFallbackIntruderVerse(verse, level, Random(seed));

            // No debe lanzar: el ejercicio es jugable tal como lo consume el juego.
            expect(
              () => LocalLlmService.validateIntruderSet(set, verse, level),
              returnsNormally,
              reason: 'verso="$verse" level=$level seed=$seed -> ${set.alteredVerse} / ${set.intruderWords}',
            );

            // Y propiedades explícitas:
            expect(set.alteredVerse.toLowerCase(), isNot(verse.toLowerCase()),
                reason: 'el alterado no puede ser idéntico al original');
            expect(set.intruderWords, hasLength(level));
          }
        }
      }
    });
  });

  group('validateIntruderSet', () {
    String original = 'En el principio creó Dios el cielo y la tierra.';

    test('rechaza el versículo idéntico (el bug "principio → principio")', () {
      final broken = IntruderVerseSet(
        alteredVerse: original,
        intruderWords: const ['principio'],
        explanation: '',
      );
      expect(() => LocalLlmService.validateIntruderSet(broken, original, 1),
          throwsA(isA<FormatException>()));
    });

    test('rechaza una intrusa que ya estaba en el original', () {
      final broken = IntruderVerseSet(
        alteredVerse: 'En el comienzo creó Dios el cielo y la tierra.',
        intruderWords: const ['Dios'], // Dios ya estaba en el original
        explanation: '',
      );
      expect(() => LocalLlmService.validateIntruderSet(broken, original, 1),
          throwsA(isA<FormatException>()));
    });

    test('rechaza cuando el número de intrusas no coincide con el nivel', () {
      final mismatch = IntruderVerseSet(
        alteredVerse: 'En el comienzo creó Dios el cielo y la tierra.',
        intruderWords: const ['comienzo'], // 1 intrusa pero pedimos nivel 2
        explanation: '',
      );
      expect(() => LocalLlmService.validateIntruderSet(mismatch, original, 2),
          throwsA(isA<FormatException>()));
    });

    test('acepta una alteración real válida', () {
      final ok = IntruderVerseSet(
        alteredVerse: 'En el comienzo creó Dios el cielo y la tierra.',
        intruderWords: const ['comienzo'],
        explanation: '',
      );
      expect(() => LocalLlmService.validateIntruderSet(ok, original, 1), returnsNormally);
    });
  });
}
