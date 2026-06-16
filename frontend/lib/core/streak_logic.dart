// Lógica pura de racha (testeable, sin estado). Misma clave de día que
// AppStore (`YYYY-MM-DD`).

String streakDayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Cuenta los días consecutivos hacia atrás desde [now] (o desde ayer, para no
/// romper la racha antes de practicar hoy). Un día cuenta si está en
/// [activeOrFrozen] (días con actividad real ∪ días cubiertos por un freeze).
int computeStreak(Set<String> activeOrFrozen, DateTime now) {
  if (activeOrFrozen.isEmpty) return 0;
  var cursor = now;
  if (!activeOrFrozen.contains(streakDayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!activeOrFrozen.contains(streakDayKey(cursor))) return 0;
  }
  var streak = 0;
  while (activeOrFrozen.contains(streakDayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Devuelve la clave de "ayer" si conviene congelarlo para salvar la racha:
/// ayer NO tuvo actividad pero antier SÍ (había una racha que hoy se rompería
/// por un solo día perdido). Devuelve null si no hay nada que salvar.
String? freezeCandidateDay(Set<String> activeDays, DateTime now) {
  final yesterday = streakDayKey(now.subtract(const Duration(days: 1)));
  final dayBefore = streakDayKey(now.subtract(const Duration(days: 2)));
  if (!activeDays.contains(yesterday) && activeDays.contains(dayBefore)) {
    return yesterday;
  }
  return null;
}
