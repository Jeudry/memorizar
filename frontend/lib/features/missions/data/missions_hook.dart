import 'package:flutter/widgets.dart';

import '../../../core/app_state.dart';
import 'missions_tracker.dart';

/// Call when the user finishes practicing a card (correct or not).
/// Updates the "practice 1 card today" and "keep your streak" missions and
/// bumps the weekly card counter.
Future<void> recordPracticeIncrement(BuildContext context) async {
  final tracker = MissionsTracker.instance;
  // Daily: at least one card today.
  await tracker.recordProgress('daily-practice-1');
  // Daily: practiced today (mirror of streak).
  await tracker.recordProgress('daily-streak');
  // Weekly: total cards memorized this week.
  await tracker.recordProgress('weekly-50cards');

  // Weekly days-practiced: only bump once per day. We approximate "practiced
  // today" by reading the daily-streak progress for the current bucket — if
  // this is the first practice of the day, recordProgress above just set it
  // to 1, so bump weekly-7days now.
  final dailyStreakProgress = await tracker.progressFor('daily-streak');
  if (dailyStreakProgress == 1) {
    await tracker.recordProgress('weekly-7days');
  }

  // Touch the store so any listening UI rebuilds (no mutation, just nudge).
  // AppScope.of throws if not mounted, so guard with a deferred check.
  if (context.mounted) {
    // ignore: unused_local_variable
    final _ = AppScope.of(context);
  }
}

/// Call when the user gets a card right. Increments the "3 correct in a row"
/// mission progress (capped at target).
Future<void> recordCorrectAnswer(BuildContext context) async {
  await MissionsTracker.instance.recordProgress('daily-perfect-3');
}

/// Call when the user gets a card wrong — resets the streak-style mission.
Future<void> recordWrongAnswer(BuildContext context) async {
  // Only reset if not already completed today (a completed mission stays
  // completed for the rest of the day even if the user fails afterwards).
  final done = await MissionsTracker.instance.isDoneToday('daily-perfect-3');
  if (!done) {
    await MissionsTracker.instance.resetProgress('daily-perfect-3');
  }
}
