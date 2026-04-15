import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/deck_memorization_health_provider.dart';

void main() {
  final deck = Deck(
    id: 'bible',
    name: 'Biblia',
    description: 'Versículos',
    type: DeckType.bible,
    accentColorIndex: 0,
    totalItems: 20,
    dueToday: 2,
    learned: 8,
    createdAt: DateTime(2026, 4, 14),
  );

  test('derives deck health with cards route when cards are weaker', () {
    final health = deriveDeckMemorizationHealth(
      deck: deck,
      exerciseConsolidations: [
        db.ExerciseConsolidation(
          id: 1,
          deckId: 'bible',
          itemId: 'i1',
          difficulty: 'beginner',
          averageScore: 0.81,
          totalMistakes: 2,
          weakestStepType: 'fill_options',
          strongestStepType: 'listen',
          createdAt: DateTime(2026, 4, 14),
        ),
      ],
      cardsConsolidations: [
        db.CardsConsolidation(
          id: 1,
          deckId: 'bible',
          averageScore: 0.48,
          totalMistakes: 61,
          weakestExerciseType: 'matching_reference',
          strongestExerciseType: 'flashcards',
          createdAt: DateTime(2026, 4, 14),
        ),
      ],
      completedRoutesByDeck: const {},
      now: DateTime(2026, 4, 14),
    );

    expect(health.primaryRoute.label, 'Modo Cards');
    expect(health.cardsAverageScore, closeTo(0.48, 0.001));
    expect(health.exerciseAverageScore, closeTo(0.81, 0.001));
  });

  test('falls back to sensible default when there is no history yet', () {
    final health = deriveDeckMemorizationHealth(
      deck: deck.copyWith(dueToday: 0),
      exerciseConsolidations: const [],
      cardsConsolidations: const [],
      completedRoutesByDeck: const {},
      now: DateTime(2026, 4, 14),
    );

    expect(health.primaryRoute.label, 'Modo Ejercicios');
    expect(health.statusLabel, isNotEmpty);
    expect(health.summary, contains('Todavía no hay suficiente historial'));
  });
}
