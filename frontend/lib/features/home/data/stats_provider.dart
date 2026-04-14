import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';

/// Activity data from real ReviewLogs.
/// Key: daysAgo (0 = today), Value: number of reviews that day.
final activityProvider = FutureProvider<Map<int, int>>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  return db.getActivityData();
});

final streakProvider = FutureProvider<int>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  return db.getStreak();
});

final totalReviewsProvider = FutureProvider<int>((ref) async {
  await ref.watch(dbReadyProvider.future);
  final db = ref.read(databaseProvider);
  return db.getTotalReviews();
});
