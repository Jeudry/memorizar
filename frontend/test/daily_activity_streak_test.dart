import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';
import 'package:frontend/core/db/app_database.dart';

/// La racha y los filtros de período se calculan del historial de actividad
/// diaria persistido en Drift (DB en memoria para el test).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  test('recordDailyActivity acumula por día y la racha cuenta días seguidos',
      () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final now = DateTime.now();
    // Tres días consecutivos terminando hoy + un día suelto hace una semana.
    for (final daysAgo in [0, 0, 1, 2, 7]) {
      await db.recordDailyActivity(
        day: dayKey(now.subtract(Duration(days: daysAgo))),
        correctDelta: 1,
        reviewedDelta: 1,
      );
    }

    final store = AppStore(enableDatabasePersistence: true, db: db);
    await store.loadDecksFromDatabase();

    expect(store.streakDays, 3,
        reason: 'hoy + ayer + antier; el hueco del día 3 corta la racha');

    final today = store.activityInLastDays(1);
    expect(today.correct, 2, reason: 'hoy se registró dos veces (upsert suma)');

    final week = store.activityInLastDays(7);
    expect(week.correct, 4, reason: 'el registro de hace 7 días queda fuera');
  });

  test('sin actividad hoy ni ayer la racha es 0', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await db.recordDailyActivity(
      day: dayKey(DateTime.now().subtract(const Duration(days: 3))),
      correctDelta: 1,
      reviewedDelta: 1,
    );

    final store = AppStore(enableDatabasePersistence: true, db: db);
    await store.loadDecksFromDatabase();

    expect(store.streakDays, 0);
  });
}
