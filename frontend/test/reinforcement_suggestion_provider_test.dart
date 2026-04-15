import 'package:flutter_test/flutter_test.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/home/data/reinforcement_suggestion_provider.dart';

void main() {
  final decks = [
    Deck(
      id: 'bible',
      name: 'Biblia',
      description: 'Versículos',
      type: DeckType.bible,
      accentColorIndex: 0,
      totalItems: 10,
      dueToday: 2,
      learned: 4,
      createdAt: DateTime(2026, 4, 14),
    ),
    Deck(
      id: 'physics',
      name: 'Física',
      description: 'Fórmulas',
      type: DeckType.general,
      accentColorIndex: 1,
      totalItems: 8,
      dueToday: 0,
      learned: 6,
      createdAt: DateTime(2026, 4, 14),
    ),
  ];

  test('suggests card mode for compare/detect style weaknesses', () {
    final consolidations = [
      db.ExerciseConsolidation(
        id: 1,
        deckId: 'bible',
        itemId: 'b1',
        difficulty: 'beginner',
        averageScore: 0.62,
        totalMistakes: 6,
        weakestStepType: 'compare_versions',
        strongestStepType: 'listen',
        createdAt: DateTime(2026, 4, 13),
      ),
    ];

    final suggestion = buildReinforcementSuggestion(
      decks: decks,
      exerciseConsolidations: consolidations,
      cardsConsolidations: const [],
      completedRoutesByDeck: const {},
      now: DateTime(2026, 4, 14),
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.deckId, 'bible');
    expect(suggestion.modeLabel, 'Modo Cards');
    expect(suggestion.primaryRoute.label, 'Modo Cards');
  });

  test('suggests exercises mode for deep recall weaknesses', () {
    final consolidations = [
      db.ExerciseConsolidation(
        id: 1,
        deckId: 'physics',
        itemId: 'p1',
        difficulty: 'intermediate',
        averageScore: 0.58,
        totalMistakes: 5,
        weakestStepType: 'recite_from_memory_voice',
        strongestStepType: 'compare_versions',
        createdAt: DateTime(2026, 4, 14),
      ),
    ];

    final suggestion = buildReinforcementSuggestion(
      decks: decks,
      exerciseConsolidations: consolidations,
      cardsConsolidations: const [],
      completedRoutesByDeck: const {},
      now: DateTime(2026, 4, 14),
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.deckId, 'physics');
    expect(suggestion.modeLabel, 'Modo Ejercicios');
    expect(suggestion.primaryRoute.label, 'Modo Ejercicios');
  });

  test('prioritizes reminder when many days passed without practice', () {
    final consolidations = [
      db.ExerciseConsolidation(
        id: 1,
        deckId: 'physics',
        itemId: 'p1',
        difficulty: 'intermediate',
        averageScore: 0.9,
        totalMistakes: 1,
        weakestStepType: 'fill_options',
        strongestStepType: 'listen',
        createdAt: DateTime(2026, 4, 7),
      ),
    ];

    final suggestion = buildReinforcementSuggestion(
      decks: decks,
      exerciseConsolidations: consolidations,
      cardsConsolidations: const [],
      completedRoutesByDeck: const {},
      now: DateTime(2026, 4, 14),
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.reason, contains('Han pasado'));
    expect(suggestion.primaryRoute.label, 'Modo Cards');
    expect(suggestion.secondaryRoute?.label, 'Modo Ejercicios');
  });

  test('suggests cards mode from cards consolidation history', () {
    final cardsConsolidations = [
      db.CardsConsolidation(
        id: 1,
        deckId: 'bible',
        averageScore: 0.44,
        totalMistakes: 89,
        weakestExerciseType: 'matching_reference',
        strongestExerciseType: 'flashcards',
        createdAt: DateTime(2026, 4, 14),
      ),
    ];

    final suggestion = buildReinforcementSuggestion(
      decks: decks,
      exerciseConsolidations: const [],
      cardsConsolidations: cardsConsolidations,
      completedRoutesByDeck: const {},
      now: DateTime(2026, 4, 14),
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.deckId, 'bible');
    expect(suggestion.modeLabel, 'Modo Cards');
    expect(suggestion.weakestExerciseLabel, 'Emparejar referencia');
    expect(suggestion.primaryRoute.label, 'Modo Cards');
    expect(suggestion.secondaryRoute?.label, 'Modo Ejercicios');
  });

  test('advances to next route step when primary step was already completed', () {
    final cardsConsolidations = [
      db.CardsConsolidation(
        id: 1,
        deckId: 'bible',
        averageScore: 0.44,
        totalMistakes: 89,
        weakestExerciseType: 'matching_reference',
        strongestExerciseType: 'flashcards',
        createdAt: DateTime(2026, 4, 14),
      ),
    ];

    final suggestion = buildReinforcementSuggestion(
      decks: decks,
      exerciseConsolidations: const [],
      cardsConsolidations: cardsConsolidations,
      completedRoutesByDeck: const {
        'bible': {'Modo Cards'},
      },
      now: DateTime(2026, 4, 14),
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.primaryRoute.label, 'Modo Ejercicios');
    expect(suggestion.modeLabel, 'Modo Ejercicios');
  });
}
