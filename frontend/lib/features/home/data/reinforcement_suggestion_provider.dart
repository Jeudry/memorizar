import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/core/db/app_database.dart' as db;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/home/data/models/reinforcement_suggestion.dart';

final reinforcementSuggestionProvider = FutureProvider<ReinforcementSuggestion?>((ref) async {
  final database = ref.watch(databaseProvider);
  final decks = await ref.watch(decksProvider.future);
  final reinforcementProgress = ref.watch(reinforcementProgressProvider);
  final exerciseConsolidations = await database.getRecentConsolidations(limit: 24);
  final cardsConsolidations = await database.getRecentCardsConsolidations(limit: 24);
  return buildReinforcementSuggestion(
    decks: decks,
    exerciseConsolidations: exerciseConsolidations,
    cardsConsolidations: cardsConsolidations,
    completedRoutesByDeck: reinforcementProgress.completedRoutesByDeck,
    now: DateTime.now(),
  );
});

ReinforcementSuggestion? buildReinforcementSuggestion({
  required List<Deck> decks,
  required List<db.ExerciseConsolidation> exerciseConsolidations,
  required List<db.CardsConsolidation> cardsConsolidations,
  required Map<String, Set<String>> completedRoutesByDeck,
  required DateTime now,
}) {
  if (decks.isEmpty) return null;

  final latestExerciseByDeck = <String, db.ExerciseConsolidation>{};
  for (final row in exerciseConsolidations) {
    latestExerciseByDeck.putIfAbsent(row.deckId, () => row);
  }

  final latestCardsByDeck = <String, db.CardsConsolidation>{};
  for (final row in cardsConsolidations) {
    latestCardsByDeck.putIfAbsent(row.deckId, () => row);
  }

  Deck? selectedDeck;
  _SuggestionSignal? selectedSignal;
  double bestPriority = -1;

  for (final deck in decks) {
    final signal = _pickBestSignal(
      exercise: latestExerciseByDeck[deck.id],
      cards: latestCardsByDeck[deck.id],
      deck: deck,
      now: now,
    );
    final route = _buildRoute(
      deckId: deck.id,
      mode: signal?.modeLabel ?? 'Modo Ejercicios',
      averageScore: signal?.averageScore,
      daysSinceLastPractice: signal == null ? null : now.difference(signal.createdAt).inDays,
    );
    final adjustedRoute = _applyCompletedRouteState(
      route,
      completedLabels: completedRoutesByDeck[deck.id] ?? const <String>{},
    );
    final priority =
        (signal?.priority ?? _defaultPriority(deck)) * (adjustedRoute.isExhausted ? 0.35 : 1);
    if (priority > bestPriority) {
      bestPriority = priority;
      selectedDeck = deck;
      selectedSignal = signal?.copyWith(route: adjustedRoute);
    }
  }

  if (selectedDeck == null) return null;
  final signal = selectedSignal;
  final daysSinceLastPractice = signal == null ? null : now.difference(signal.createdAt).inDays;
  final weakest = _labelForStorageValue(signal?.weakestType, signal?.modeLabel);
  final mode = signal?.modeLabel ?? 'Modo Ejercicios';
  final route = signal?.route ??
      _buildRoute(
        deckId: selectedDeck.id,
        mode: mode,
        averageScore: signal?.averageScore,
        daysSinceLastPractice: daysSinceLastPractice,
      );
  final reason = _buildReason(
    deckName: selectedDeck.name,
    weakestLabel: weakest,
    daysSinceLastPractice: daysSinceLastPractice,
    averageScore: signal?.averageScore,
  );

  return ReinforcementSuggestion(
    deckId: selectedDeck.id,
    deckName: selectedDeck.name,
    modeLabel: route.primary.label,
    reason: reason,
    ctaLabel: 'Empezar por ${route.primary.label.toLowerCase()}',
    primaryRoute: route.primary,
    secondaryRoute: route.secondary,
    weakestExerciseLabel: weakest,
    daysSinceLastPractice: daysSinceLastPractice,
  );
}

double _defaultPriority(Deck deck) {
  return 0.12 + (deck.dueToday > 0 ? 0.18 : 0.0);
}

_SuggestionSignal? _pickBestSignal({
  required db.ExerciseConsolidation? exercise,
  required db.CardsConsolidation? cards,
  required Deck deck,
  required DateTime now,
}) {
  final candidates = <_SuggestionSignal>[
    if (exercise != null)
      _SuggestionSignal(
        modeLabel: _suggestExerciseMode(exercise.weakestStepType),
        averageScore: exercise.averageScore,
        weakestType: exercise.weakestStepType,
        createdAt: exercise.createdAt,
        priority: _priorityFor(
          averageScore: exercise.averageScore,
          createdAt: exercise.createdAt,
          dueToday: deck.dueToday,
          hasHistory: true,
          now: now,
        ),
      ),
    if (cards != null)
      _SuggestionSignal(
        modeLabel: 'Modo Cards',
        averageScore: cards.averageScore,
        weakestType: cards.weakestExerciseType,
        createdAt: cards.createdAt,
        priority: _priorityFor(
          averageScore: cards.averageScore,
          createdAt: cards.createdAt,
          dueToday: deck.dueToday,
          hasHistory: true,
          now: now,
        ) +
            0.05,
      ),
  ];

  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.priority.compareTo(a.priority));
  return candidates.first;
}

double _priorityFor({
  required double averageScore,
  required DateTime createdAt,
  required int dueToday,
  required bool hasHistory,
  DateTime? now,
}) {
  final weakness = 1 - averageScore;
  final daysSince = (now ?? DateTime.now()).difference(createdAt).inDays;
  final reminderWeight = daysSince >= 3 ? (daysSince / 7).clamp(0.0, 1.5) : 0.0;
  final dueWeight = dueToday > 0 ? 0.18 : 0.0;
  final historyWeight = hasHistory ? 0.25 : 0.0;
  return weakness + reminderWeight + dueWeight + historyWeight;
}

String _suggestExerciseMode(String? weakestStepType) {
  switch (weakestStepType) {
    case 'compare_versions':
    case 'detect_errors':
      return 'Modo Cards';
    default:
      return 'Modo Ejercicios';
  }
}

String? _labelForStorageValue(String? storageValue, String? modeLabel) {
  if (modeLabel == 'Modo Cards') {
    switch (storageValue) {
      case 'flashcards':
        return 'Flashcards clásicas';
      case 'matching_reference':
        return 'Emparejar referencia';
      case 'detect_intruder':
        return 'Detectar intruso';
      default:
        return null;
    }
  }
  switch (storageValue) {
    case 'listen':
      return 'Escuchar';
    case 'read_along':
      return 'Leer';
    case 'reconstruct_blocks':
      return 'Reconstruir bloques';
    case 'thematic_blocks':
      return 'Bloques temáticos';
    case 'segmented_recall':
      return 'Memorización por tramos';
    case 'record_reading':
      return 'Grabar tu voz';
    case 'play_recording':
      return 'Escuchar grabación';
    case 'read_hidden_with_voice':
      return 'Leer ocultado por voz';
    case 'reverse_reference':
      return 'Referencia inversa';
    case 'compare_versions':
      return 'Comparar versiones';
    case 'cut_in':
      return 'Modo corte';
    case 'random_start':
      return 'Arranque aleatorio';
    case 'fill_options':
      return 'Completar';
    case 'type_first_letter':
      return 'Primera letra';
    case 'understanding_question':
      return 'Entendimiento IA';
    case 'detect_errors':
      return 'Detectar errores';
    case 'recite_from_memory_voice':
      return 'Decirlo de memoria';
    case 'pressure_recall':
      return 'Modo presión';
    case 'total_exam':
      return 'Examen total';
    case 'coach_review':
      return 'Coach IA';
    default:
      return null;
  }
}

String _buildReason({
  required String deckName,
  required String? weakestLabel,
  required int? daysSinceLastPractice,
  required double? averageScore,
}) {
  if (daysSinceLastPractice != null && daysSinceLastPractice >= 3) {
    return 'Han pasado $daysSinceLastPractice días desde tu última práctica de $deckName.';
  }
  if (weakestLabel != null && averageScore != null) {
    return 'Tu punto más débil reciente fue $weakestLabel con ${(averageScore * 100).round()}% promedio.';
  }
  return 'Te conviene reforzar $deckName con una sesión corta para mantener el progreso.';
}

_BuiltRoute _buildRoute({
  required String deckId,
  required String mode,
  required double? averageScore,
  required int? daysSinceLastPractice,
}) {
  final cards = ReinforcementRouteStep(
    label: 'Modo Cards',
    routePath: '/decks/$deckId/cards',
    description: 'Recupera contexto general y reduce confusiones entre items cercanos.',
  );
  final exercises = ReinforcementRouteStep(
    label: 'Modo Ejercicios',
    routePath: '/decks/$deckId/practice',
    description: 'Refuerza recuerdo profundo, audio y precisión del contenido.',
  );

  if (mode == 'Modo Cards') {
    final needsDeepFollowUp = (averageScore ?? 1) < 0.72 || (daysSinceLastPractice ?? 0) >= 5;
    return _BuiltRoute(
      primary: cards,
      secondary: needsDeepFollowUp ? exercises : null,
    );
  }

  final warmUpFirst = (daysSinceLastPractice ?? 0) >= 5;
  if (warmUpFirst) {
    return _BuiltRoute(primary: cards, secondary: exercises);
  }

  final needsGeneralization = (averageScore ?? 1) < 0.65;
  return _BuiltRoute(
    primary: exercises,
    secondary: needsGeneralization ? cards : null,
  );
}

class _SuggestionSignal {
  const _SuggestionSignal({
    required this.modeLabel,
    required this.averageScore,
    required this.weakestType,
    required this.createdAt,
    required this.priority,
    this.route,
  });

  final String modeLabel;
  final double averageScore;
  final String? weakestType;
  final DateTime createdAt;
  final double priority;
  final _BuiltRoute? route;

  _SuggestionSignal copyWith({
    String? modeLabel,
    double? averageScore,
    String? weakestType,
    DateTime? createdAt,
    double? priority,
    _BuiltRoute? route,
  }) {
    return _SuggestionSignal(
      modeLabel: modeLabel ?? this.modeLabel,
      averageScore: averageScore ?? this.averageScore,
      weakestType: weakestType ?? this.weakestType,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      route: route ?? this.route,
    );
  }
}

class _BuiltRoute {
  const _BuiltRoute({
    required this.primary,
    this.secondary,
    this.isExhausted = false,
  });

  final ReinforcementRouteStep primary;
  final ReinforcementRouteStep? secondary;
  final bool isExhausted;
}

_BuiltRoute _applyCompletedRouteState(
  _BuiltRoute route, {
  required Set<String> completedLabels,
}) {
  if (!completedLabels.contains(route.primary.label)) {
    return route;
  }
  if (route.secondary != null && !completedLabels.contains(route.secondary!.label)) {
    return _BuiltRoute(primary: route.secondary!, isExhausted: false);
  }
  return _BuiltRoute(primary: route.primary, secondary: route.secondary, isExhausted: true);
}
