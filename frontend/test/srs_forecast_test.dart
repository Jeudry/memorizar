import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/srs_forecast.dart';

void main() {
  final now = DateTime(2026, 6, 16, 10);
  DateTime inDays(int d) => now.add(Duration(days: d));

  test('vencidas y sin fecha cuentan en dueNow', () {
    final f = computeForecast([
      (isDue: true, next: null),
      (isDue: true, next: inDays(3)),
      (isDue: false, next: null),
      (isDue: false, next: inDays(-1)), // fecha pasada
    ], now);
    expect(f.dueNow, 4);
    expect(f.weekTotal, 4);
  });

  test('reparte por día en próximos 7', () {
    final f = computeForecast([
      (isDue: false, next: inDays(1)),
      (isDue: false, next: inDays(1)),
      (isDue: false, next: inDays(7)),
      (isDue: false, next: inDays(8)), // fuera de ventana
    ], now);
    expect(f.dueNow, 0);
    expect(f.tomorrow, 2);
    expect(f.next7[6], 1); // día +7
    expect(f.weekTotal, 3); // el de +8 no cuenta
  });

  test('vacío', () {
    final f = computeForecast(const [], now);
    expect(f.dueNow, 0);
    expect(f.weekTotal, 0);
  });
}
