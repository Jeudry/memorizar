import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/streak_logic.dart';

void main() {
  final now = DateTime(2026, 6, 16, 10);
  String k(int daysAgo) =>
      streakDayKey(now.subtract(Duration(days: daysAgo)));

  group('computeStreak', () {
    test('cuenta días consecutivos desde hoy', () {
      final active = {k(0), k(1), k(2)};
      expect(computeStreak(active, now), 3);
    });

    test('no rompe si hoy aún no se practicó pero ayer sí', () {
      final active = {k(1), k(2)};
      expect(computeStreak(active, now), 2);
    });

    test('un hueco corta la racha', () {
      final active = {k(0), k(2), k(3)}; // falta ayer (k(1))
      expect(computeStreak(active, now), 1);
    });

    test('un día congelado puentea el hueco', () {
      final active = {k(0), k(2), k(3), k(1)}; // k(1) "congelado" incluido
      expect(computeStreak(active, now), 4);
    });

    test('vacío = 0', () => expect(computeStreak({}, now), 0));
  });

  group('freezeCandidateDay', () {
    test('propone ayer si ayer falta y antier estuvo activo', () {
      final active = {k(2), k(3)}; // ayer (k1) falta, antier (k2) activo
      expect(freezeCandidateDay(active, now), k(1));
    });

    test('null si ayer estuvo activo', () {
      expect(freezeCandidateDay({k(1), k(2)}, now), isNull);
    });

    test('null si no había racha que salvar (antier tampoco activo)', () {
      expect(freezeCandidateDay({k(5)}, now), isNull);
    });
  });
}
