import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/home/data/models/achievement_badge.dart';
import 'package:memorizar/features/home/data/stats_provider.dart';

final achievementsProvider = FutureProvider<List<AchievementBadge>>((ref) async {
  final database = ref.watch(databaseProvider);
  final streak = await ref.watch(streakProvider.future);
  final totalReviews = await ref.watch(totalReviewsProvider.future);
  final exerciseConsolidations = await database.getRecentConsolidations(limit: 40);
  final cardsConsolidations = await database.getRecentCardsConsolidations(limit: 40);

  final hasDeepPractice = exerciseConsolidations.isNotEmpty;
  final hasCardsPractice = cardsConsolidations.isNotEmpty;
  final averagePractice = exerciseConsolidations.isEmpty
      ? 0.0
      : exerciseConsolidations.map((entry) => entry.averageScore).reduce((a, b) => a + b) /
          exerciseConsolidations.length;

  return [
    AchievementBadge(
      code: 'first_steps',
      title: 'Primeros pasos',
      description: 'Completa tu primera práctica guiada.',
      unlocked: hasDeepPractice,
      unlockedAt: hasDeepPractice ? exerciseConsolidations.first.createdAt : null,
    ),
    AchievementBadge(
      code: 'cards_scout',
      title: 'Explorador de cards',
      description: 'Completa tu primera sesión de modo cards.',
      unlocked: hasCardsPractice,
      unlockedAt: hasCardsPractice ? cardsConsolidations.first.createdAt : null,
    ),
    AchievementBadge(
      code: 'streak_7',
      title: 'Racha de 7 días',
      description: 'Mantén una semana seguida de práctica.',
      unlocked: streak >= 7,
    ),
    AchievementBadge(
      code: 'century',
      title: 'Cien repasos',
      description: 'Alcanza 100 repasos acumulados.',
      unlocked: totalReviews >= 100,
    ),
    AchievementBadge(
      code: 'deep_focus',
      title: 'Memoria afilada',
      description: 'Mantén 80% promedio reciente en ejercicios.',
      unlocked: averagePractice >= 0.8 && hasDeepPractice,
    ),
  ];
});
