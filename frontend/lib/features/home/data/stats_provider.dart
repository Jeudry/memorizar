import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';

final activityProvider = FutureProvider<Map<int, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getActivityData(days: 63);
});

final streakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getStreak();
});

final totalReviewsProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getTotalReviews();
});
