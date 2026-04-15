import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/features/decks/data/models/deck_memorization_health.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/home/data/models/reinforcement_suggestion.dart';
import 'package:memorizar/features/home/data/reinforcement_suggestion_provider.dart';

final deckMemorizationHealthProvider =
    FutureProvider.family<DeckMemorizationHealth?, String>((ref, deckId) async {
  final deck = await ref.watch(deckByIdProvider(deckId).future);
  if (deck == null) return null;

  final database = ref.watch(databaseProvider);
  final reinforcementProgress = ref.watch(reinforcementProgressProvider);
  final exerciseConsolidations = await database.getRecentConsolidationsForDeck(deckId, limit: 8);
  final cardsConsolidations = await database.getRecentCardsConsolidationsForDeck(deckId, limit: 8);

  return deriveDeckMemorizationHealth(
    deck: deck,
    exerciseConsolidations: exerciseConsolidations,
    cardsConsolidations: cardsConsolidations,
    completedRoutesByDeck: reinforcementProgress.completedRoutesByDeck,
    now: DateTime.now(),
  );
});

DeckMemorizationHealth deriveDeckMemorizationHealth({
  required Deck deck,
  required List<db.ExerciseConsolidation> exerciseConsolidations,
  required List<db.CardsConsolidation> cardsConsolidations,
  required Map<String, Set<String>> completedRoutesByDeck,
  required DateTime now,
}) {
  final suggestion = buildReinforcementSuggestion(
    decks: [deck],
    exerciseConsolidations: exerciseConsolidations,
    cardsConsolidations: cardsConsolidations,
    completedRoutesByDeck: completedRoutesByDeck,
    now: now,
  );

  final exerciseAverage = exerciseConsolidations.isEmpty
      ? null
      : exerciseConsolidations.map((entry) => entry.averageScore).reduce((a, b) => a + b) /
          exerciseConsolidations.length;
  final cardsAverage = cardsConsolidations.isEmpty
      ? null
      : cardsConsolidations.map((entry) => entry.averageScore).reduce((a, b) => a + b) /
          cardsConsolidations.length;

  final scoreInputs = [exerciseAverage, cardsAverage].whereType<double>().toList();
  final baseScore =
      scoreInputs.isEmpty ? 0.58 : scoreInputs.reduce((a, b) => a + b) / scoreInputs.length;
  final duePenalty = (deck.dueToday * 0.03).clamp(0.0, 0.18);
  final healthScore = (baseScore - duePenalty).clamp(0.0, 1.0);

  final statusLabel = switch (healthScore) {
    >= 0.82 => 'Fuerte',
    >= 0.65 => 'En progreso',
    _ => 'Necesita refuerzo',
  };

  final defaultPrimary = ReinforcementRouteStep(
    label: deck.dueToday > 0 ? 'Repaso SRS' : 'Modo Ejercicios',
    routePath: deck.dueToday > 0 ? '/review/${deck.id}' : '/decks/${deck.id}/practice',
    description: deck.dueToday > 0
        ? 'Atiende primero las tarjetas pendientes de hoy.'
        : 'Empieza a profundizar el contenido del deck.',
  );
  final hasHistory = exerciseConsolidations.isNotEmpty || cardsConsolidations.isNotEmpty;

  return DeckMemorizationHealth(
    healthScore: healthScore,
    statusLabel: statusLabel,
    summary: hasHistory
        ? (suggestion?.reason ??
            'Te conviene reforzar este deck con una sesión corta para mantener el progreso.')
        : 'Todavía no hay suficiente historial. Una sesión corta te ayudará a calibrar este deck.',
    primaryRoute: suggestion?.primaryRoute ?? defaultPrimary,
    secondaryRoute: suggestion?.secondaryRoute,
    exerciseAverageScore: exerciseAverage,
    cardsAverageScore: cardsAverage,
  );
}
