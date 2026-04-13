import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simulated activity data for the heatmap.
/// Key: days ago (0 = today), Value: reviews done that day.
final activityProvider = Provider<Map<int, int>>((ref) {
  return {
    0: 5,
    1: 8,
    2: 3,
    3: 0,
    4: 12,
    5: 7,
    6: 5,
    7: 9,
    8: 4,
    9: 0,
    10: 6,
    11: 11,
    12: 3,
    13: 8,
    14: 5,
    15: 0,
    16: 7,
    17: 4,
    18: 9,
    19: 2,
    20: 6,
    21: 8,
    22: 0,
    23: 5,
    24: 10,
    25: 3,
    26: 7,
    27: 0,
    28: 4,
    29: 6,
    30: 8,
    31: 5,
    32: 0,
    33: 9,
    34: 3,
    35: 7,
    36: 0,
    37: 6,
    38: 4,
    39: 11,
    40: 5,
    41: 0,
    42: 8,
    43: 3,
    44: 7,
    45: 6,
    46: 0,
    47: 4,
    48: 9,
    49: 5,
    50: 8,
    51: 0,
    52: 3,
    53: 7,
    54: 6,
    55: 4,
    56: 0,
    57: 5,
    58: 8,
    59: 3,
    60: 0,
    61: 7,
    62: 6,
    63: 4,
  };
});

final streakProvider = Provider<int>((ref) {
  final activity = ref.watch(activityProvider);
  int streak = 0;
  for (int i = 0; i <= 30; i++) {
    if ((activity[i] ?? 0) > 0) {
      streak++;
    } else if (i > 0) {
      break;
    }
  }
  return streak;
});

final totalReviewsProvider = Provider<int>((ref) {
  final activity = ref.watch(activityProvider);
  return activity.values.fold(0, (a, b) => a + b);
});
