// Pronóstico SRS puro (testeable): proyecta las tarjetas a buckets por día
// según su próxima fecha de repaso.

/// Resultado del pronóstico: vencidas ahora + conteo por los próximos 7 días.
class ReviewForecast {
  /// Tarjetas vencidas o nunca repasadas (toca repasarlas ya).
  final int dueNow;

  /// Conteo de tarjetas que vencen en cada uno de los próximos 7 días
  /// (índice 0 = mañana, … índice 6 = dentro de 7 días).
  final List<int> next7;

  const ReviewForecast(this.dueNow, this.next7);

  int get tomorrow => next7.isNotEmpty ? next7[0] : 0;

  /// Total que vencerá de hoy a 7 días (incluye las de ahora).
  int get weekTotal => dueNow + next7.fold(0, (a, b) => a + b);

  static const empty = ReviewForecast(0, [0, 0, 0, 0, 0, 0, 0]);
}

/// Calcula el pronóstico a partir de cada tarjeta (si está vencida y su próxima
/// fecha de repaso) y la hora [now]. Las vencidas o sin fecha cuentan en
/// [ReviewForecast.dueNow]; el resto se reparte por día (1..7).
ReviewForecast computeForecast(
  Iterable<({bool isDue, DateTime? next})> cards,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  var dueNow = 0;
  final buckets = List<int>.filled(7, 0);
  for (final c in cards) {
    final d = c.next;
    // Vencida o sin fecha programada → toca repasarla ya.
    if (c.isDue || d == null) {
      dueNow++;
      continue;
    }
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff <= 0) {
      dueNow++;
    } else if (diff <= 7) {
      buckets[diff - 1]++;
    }
  }
  return ReviewForecast(dueNow, buckets);
}
