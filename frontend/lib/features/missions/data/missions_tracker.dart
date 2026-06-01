import 'package:shared_preferences/shared_preferences.dart';

import 'missions.dart';

/// Tracks per-mission progress in SharedPreferences, scoped to the current
/// daily or weekly bucket (mission progress automatically "resets" when the
/// bucket changes because we read/write a new key).
class MissionsTracker {
  MissionsTracker._();

  static final MissionsTracker instance = MissionsTracker._();

  static const _prefix = 'memorizar.missions';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns the bucket suffix for [mission] for the given [now] timestamp.
  /// Daily: yyyy-MM-dd. Weekly: yyyy-W## (ISO 8601 week number).
  String bucketFor(Mission mission, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    if (mission.period == MissionPeriod.daily) {
      final y = reference.year.toString().padLeft(4, '0');
      final m = reference.month.toString().padLeft(2, '0');
      final d = reference.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    final week = _isoWeekNumber(reference);
    final weekYear = _isoWeekYear(reference);
    final y = weekYear.toString().padLeft(4, '0');
    final w = week.toString().padLeft(2, '0');
    return '$y-W$w';
  }

  String _progressKey(Mission mission, [DateTime? now]) =>
      '$_prefix.${mission.id}.${bucketFor(mission, now)}.progress';

  String _doneKey(Mission mission, [DateTime? now]) =>
      '$_prefix.${mission.id}.${bucketFor(mission, now)}.done';

  Future<int> progressFor(String missionId) async {
    final mission = missionById(missionId);
    if (mission == null) return 0;
    final prefs = await _getPrefs();
    return prefs.getInt(_progressKey(mission)) ?? 0;
  }

  Future<bool> isDoneToday(String missionId) async {
    final mission = missionById(missionId);
    if (mission == null) return false;
    final prefs = await _getPrefs();
    return prefs.getBool(_doneKey(mission)) ?? false;
  }

  Future<void> markDone(String missionId) async {
    final mission = missionById(missionId);
    if (mission == null) return;
    final prefs = await _getPrefs();
    await prefs.setBool(_doneKey(mission), true);
  }

  Future<void> recordProgress(String missionId, {int amount = 1}) async {
    if (amount <= 0) return;
    final mission = missionById(missionId);
    if (mission == null) return;
    final prefs = await _getPrefs();
    final key = _progressKey(mission);
    final current = prefs.getInt(key) ?? 0;
    final next = current + amount;
    await prefs.setInt(key, next);
    if (next >= mission.target) {
      await prefs.setBool(_doneKey(mission), true);
    }
  }

  /// Sets progress to an absolute value (clamped at >= current). Useful for
  /// monotonic counters like "days practiced this week".
  Future<void> setProgressAtLeast(String missionId, int value) async {
    if (value <= 0) return;
    final mission = missionById(missionId);
    if (mission == null) return;
    final prefs = await _getPrefs();
    final key = _progressKey(mission);
    final current = prefs.getInt(key) ?? 0;
    if (value <= current) return;
    await prefs.setInt(key, value);
    if (value >= mission.target) {
      await prefs.setBool(_doneKey(mission), true);
    }
  }

  /// Resets progress for a mission (current bucket only). Used by tests and
  /// internal helpers for streak-break counters like "perfect-3" that must
  /// drop to zero on a wrong answer.
  Future<void> resetProgress(String missionId) async {
    final mission = missionById(missionId);
    if (mission == null) return;
    final prefs = await _getPrefs();
    await prefs.setInt(_progressKey(mission), 0);
  }

  // ISO 8601 week number — week starts Monday, week 1 contains Jan 4th.
  int _isoWeekNumber(DateTime date) {
    final thursday = _isoThursdayOfWeek(date);
    final firstThursday = _isoThursdayOfWeek(DateTime(thursday.year, 1, 4));
    final diffDays = thursday.difference(firstThursday).inDays;
    return 1 + (diffDays ~/ 7);
  }

  int _isoWeekYear(DateTime date) => _isoThursdayOfWeek(date).year;

  DateTime _isoThursdayOfWeek(DateTime date) {
    // Monday = 1, Sunday = 7. Thursday is weekday 4.
    final d = DateTime(date.year, date.month, date.day);
    return d.add(Duration(days: 4 - d.weekday));
  }
}
