import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/srs/sm2.dart';

void main() {
  final now = DateTime(2026, 6, 12, 10);

  test('progresión clásica de aciertos: 1d → 6d → interval×EF', () {
    var state = const Sm2State();

    state = applySm2(state, correct: true, now: now);
    expect(state.repetitions, 1);
    expect(state.intervalDays, 1);
    expect(state.easeFactor, Sm2State.defaultEaseFactor,
        reason: 'calidad 4 mantiene el EF');
    expect(state.nextReviewAt, now.add(const Duration(days: 1)));

    state = applySm2(state, correct: true, now: now);
    expect(state.repetitions, 2);
    expect(state.intervalDays, 6);

    state = applySm2(state, correct: true, now: now);
    expect(state.repetitions, 3);
    expect(state.intervalDays, 15, reason: '6 × 2.5 = 15');
    expect(state.nextReviewAt, now.add(const Duration(days: 15)));
  });

  test('un fallo resetea las repeticiones y baja el ease factor', () {
    var state = const Sm2State();
    state = applySm2(state, correct: true, now: now);
    state = applySm2(state, correct: true, now: now);

    state = applySm2(state, correct: false, now: now);
    expect(state.repetitions, 0);
    expect(state.intervalDays, 1, reason: 'la tarjeta fallada vuelve mañana');
    expect(state.easeFactor, closeTo(2.18, 0.001),
        reason: 'calidad 2: EF − 0.32');
    expect(state.nextReviewAt, now.add(const Duration(days: 1)));
  });

  test('el ease factor nunca baja de 1.3', () {
    var state = const Sm2State(easeFactor: 1.35);
    state = applySm2(state, correct: false, now: now);
    expect(state.easeFactor, Sm2State.minEaseFactor);
  });

  test('isDue: nuevas siempre due, futuras no, vencidas sí', () {
    expect(isDue(const Sm2State(), now: now), isTrue);

    final future = Sm2State(nextReviewAt: now.add(const Duration(days: 3)));
    expect(isDue(future, now: now), isFalse);

    final overdue =
        Sm2State(nextReviewAt: now.subtract(const Duration(hours: 1)));
    expect(isDue(overdue, now: now), isTrue);
  });
}
