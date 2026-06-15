/// Algoritmo SM-2 (SuperMemo 2) adaptado a respuestas binarias.
/// La app evalúa correct/incorrect; lo mapeamos a la escala de calidad de
/// SM-2 (correcta → 4, incorrecta → 2) manteniendo la fórmula clásica de
/// ease factor e intervalos 1d → 6d → interval×EF.
library;

/// Estado SRS de una tarjeta antes/después de un repaso.
class Sm2State {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;

  const Sm2State({
    this.easeFactor = defaultEaseFactor,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.nextReviewAt,
  });

  static const double defaultEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
}

const int _qualityCorrect = 4;
const int _qualityIncorrect = 2;

double _nextEaseFactor(double current, int quality) {
  final updated =
      current + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  return updated < Sm2State.minEaseFactor ? Sm2State.minEaseFactor : updated;
}

/// Aplica un repaso al estado SM-2. [now] inyectable para tests.
Sm2State applySm2(Sm2State current, {required bool correct, DateTime? now}) {
  final reviewedAt = now ?? DateTime.now();
  final quality = correct ? _qualityCorrect : _qualityIncorrect;
  final easeFactor = _nextEaseFactor(current.easeFactor, quality);

  if (!correct) {
    // Fallo: la tarjeta vuelve al inicio y se repasa mañana.
    return Sm2State(
      easeFactor: easeFactor,
      intervalDays: 1,
      repetitions: 0,
      nextReviewAt: reviewedAt.add(const Duration(days: 1)),
    );
  }

  final repetitions = current.repetitions + 1;
  final int intervalDays;
  if (repetitions == 1) {
    intervalDays = 1;
  } else if (repetitions == 2) {
    intervalDays = 6;
  } else {
    intervalDays = (current.intervalDays * easeFactor).round();
  }

  return Sm2State(
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    repetitions: repetitions,
    nextReviewAt: reviewedAt.add(Duration(days: intervalDays)),
  );
}

/// Una tarjeta está "due" si nunca se repasó o si su fecha ya venció.
bool isDue(Sm2State state, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final next = state.nextReviewAt;
  return next == null || !next.isAfter(reference);
}
