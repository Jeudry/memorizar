import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/core/theme/app_theme.dart';
import 'package:memorizar/core/theme/theme_provider.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/models/deck_memorization_health.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/deck_memorization_health_provider.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/decks/presentation/screens/deck_detail_screen.dart';
import 'package:memorizar/features/home/data/models/reinforcement_suggestion.dart';
import 'package:memorizar/features/home/data/models/achievement_badge.dart';
import 'package:memorizar/features/home/data/reinforcement_suggestion_provider.dart';
import 'package:memorizar/features/home/data/stats_provider.dart';
import 'package:memorizar/features/practice/data/models/answer_evaluation_result.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/exercise_consolidation_record.dart';
import 'package:memorizar/features/practice/data/models/exercise_level.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_args.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_state.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_goal.dart';
import 'package:memorizar/features/practice/data/models/memorization_journey.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/memorization_plan_summary.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/home/data/achievements_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_consolidations_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_goals_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_journeys_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_plans_provider.dart';
import 'package:memorizar/features/practice/presentation/screens/exercise_session_screen.dart';
import 'package:memorizar/features/practice/presentation/screens/practice_setup_screen.dart';
import 'package:memorizar/features/home/presentation/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final deck = Deck(
    id: 'bible',
    name: 'Biblia',
    description: 'Versos y pasajes para memorizar con práctica guiada.',
    type: DeckType.bible,
    accentColorIndex: 1,
    totalItems: 3,
    dueToday: 2,
    learned: 1,
    createdAt: DateTime(2026, 4, 14),
    emoji: '📖',
  );

  final items = [
    const Item(
      id: 'b1',
      deckId: 'bible',
      front: 'Juan 3:16',
      back: 'Porque de tal manera amó Dios al mundo que ha dado a su Hijo unigénito.',
      book: 'Juan',
      chapter: 3,
      verse: 16,
    ),
    const Item(
      id: 'b2',
      deckId: 'bible',
      front: 'Salmo 119:11',
      back: 'En mi corazón he guardado tus dichos para no pecar contra ti.',
      book: 'Salmos',
      chapter: 119,
      verse: 11,
    ),
    const Item(
      id: 'b3',
      deckId: 'bible',
      front: 'Filipenses 4:13',
      back: 'Todo lo puedo en Cristo que me fortalece.',
      book: 'Filipenses',
      chapter: 4,
      verse: 13,
    ),
  ];

  final plans = [
    MemorizationPlanSummary(
      id: 'plan_beginner',
      deckId: 'bible',
      name: 'Plan Principiante',
      difficulty: MemorizationDifficulty.beginner,
      itemCount: items.length,
      createdAt: DateTime(2026, 4, 14, 9, 30),
    ),
  ];

  final consolidations = [
    ExerciseConsolidationRecord(
      id: 1,
      deckId: 'bible',
      itemId: 'b1',
      difficulty: MemorizationDifficulty.beginner,
      averageScore: 0.82,
      totalMistakes: 3,
      createdAt: DateTime(2026, 4, 14, 10, 0),
      weakestStepType: ExerciseStepType.detectErrors,
      strongestStepType: ExerciseStepType.listen,
    ),
    ExerciseConsolidationRecord(
      id: 2,
      deckId: 'bible',
      itemId: 'b2',
      difficulty: MemorizationDifficulty.intermediate,
      averageScore: 0.74,
      totalMistakes: 5,
      createdAt: DateTime(2026, 4, 14, 11, 0),
      weakestStepType: ExerciseStepType.fillOptions,
      strongestStepType: ExerciseStepType.reconstructBlocks,
    ),
  ];

  final deckHealth = DeckMemorizationHealth(
    healthScore: 0.71,
    statusLabel: 'En progreso',
    summary: 'Tu punto más débil reciente fue Emparejar referencia con 61% promedio.',
    primaryRoute: const ReinforcementRouteStep(
      label: 'Modo Cards',
      routePath: '/decks/bible/cards',
      description: 'Recupera contexto general y reduce confusiones entre items cercanos.',
    ),
    secondaryRoute: const ReinforcementRouteStep(
      label: 'Modo Ejercicios',
      routePath: '/decks/bible/practice',
      description: 'Refuerza recuerdo profundo, audio y precisión del contenido.',
    ),
    exerciseAverageScore: 0.78,
    cardsAverageScore: 0.61,
  );

  final homeSuggestion = const ReinforcementSuggestion(
    deckId: 'bible',
    deckName: 'Biblia',
    modeLabel: 'Modo Cards',
    reason: 'Han pasado 4 días desde tu última práctica de Biblia.',
    ctaLabel: 'Empezar por modo cards',
    primaryRoute: ReinforcementRouteStep(
      label: 'Modo Cards',
      routePath: '/decks/bible/cards',
      description: 'Recupera contexto general y reduce confusiones entre items cercanos.',
    ),
    secondaryRoute: ReinforcementRouteStep(
      label: 'Modo Ejercicios',
      routePath: '/decks/bible/practice',
      description: 'Refuerza recuerdo profundo, audio y precisión del contenido.',
    ),
    weakestExerciseLabel: 'Emparejar referencia',
    daysSinceLastPractice: 4,
  );

  final reinforcementState = ReinforcementProgressState(
    completedRoutesByDeck: const {
      'bible': {'Modo Cards'},
    },
    history: [
      ReinforcementHistoryEntry(
        deckId: 'bible',
        routeLabel: 'Modo Cards',
        completedAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      ReinforcementHistoryEntry(
        deckId: 'bible',
        routeLabel: 'Modo Ejercicios',
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReinforcementHistoryEntry(
        deckId: 'bible',
        routeLabel: 'Repaso SRS',
        completedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  );

  final goals = [
    MemorizationGoal(
      id: 'goal_1',
      deckId: 'bible',
      title: 'Dominar 30 items',
      objective: 'Más profundo',
      targetItems: 30,
      createdAt: DateTime(2026, 4, 14),
      targetDate: DateTime(2026, 5, 14),
    ),
  ];

  final journeys = [
    MemorizationJourney(
      id: 'journey_1',
      deckId: 'bible',
      title: 'Completar en 365 días',
      targetDays: 365,
      itemsPerDay: 1,
      targetItemCount: 3,
      objective: 'Más profundo',
      createdAt: DateTime(2026, 4, 14),
    ),
  ];

  final achievements = [
    const AchievementBadge(
      code: 'first_steps',
      title: 'Primeros pasos',
      description: 'Completa tu primera práctica guiada.',
      unlocked: true,
    ),
    const AchievementBadge(
      code: 'cards_scout',
      title: 'Explorador de cards',
      description: 'Completa tu primera sesión de modo cards.',
      unlocked: true,
    ),
  ];

  final cooperativeFollowUp = CooperativeFollowUpState(
    deckId: 'bible',
    title: 'Próxima dinámica sugerida',
    message: 'La próxima prueben Cadena: ya tienen base para enlazar la memoria paso por paso.',
    createdAt: DateTime(2026, 4, 14, 12, 0),
  );

  List<Override> buildOverrides() {
    return [
      deckByIdProvider.overrideWith((ref, id) async => id == deck.id ? deck : null),
      itemsForDeckProvider.overrideWith((ref, deckId) async => deckId == deck.id ? items : const <Item>[]),
      dueItemsProvider.overrideWith((ref, deckId) async => deckId == deck.id ? items.take(2).toList() : const <Item>[]),
      deckMemorizationHealthProvider.overrideWith(
        (ref, deckId) async => deckId == deck.id ? deckHealth : null,
      ),
      memorizationPlansProvider.overrideWith(
        (ref, deckId) async => deckId == deck.id ? plans : const <MemorizationPlanSummary>[],
      ),
      memorizationGoalsProvider.overrideWith(
        (ref, deckId) async => deckId == deck.id ? goals : const <MemorizationGoal>[],
      ),
      memorizationJourneysProvider.overrideWith(
        (ref, deckId) async => deckId == deck.id ? journeys : const <MemorizationJourney>[],
      ),
      recentDeckConsolidationsProvider.overrideWith(
        (ref, deckId) async => deckId == deck.id ? consolidations : const <ExerciseConsolidationRecord>[],
      ),
      recentItemConsolidationsProvider.overrideWith(
        (ref, itemId) async => itemId == 'b1' ? consolidations.where((record) => record.itemId == itemId).toList() : const <ExerciseConsolidationRecord>[],
      ),
      decksProvider.overrideWith((ref) async => [deck]),
      totalDueTodayProvider.overrideWith((ref) async => 2),
      streakProvider.overrideWith((ref) async => 7),
      totalReviewsProvider.overrideWith((ref) async => 34),
      activityProvider.overrideWith(
        (ref) async => {
          for (var i = 0; i < 18; i += 1) i: (i % 5) + 1,
        },
      ),
      smartReminderOptInProvider.overrideWith((ref) => _TestSmartReminderNotifier(true)),
      cooperativeFollowUpProvider.overrideWith((ref) => _TestCooperativeFollowUpNotifier(cooperativeFollowUp)),
      achievementsProvider.overrideWith((ref) async => achievements),
      themeModeProvider.overrideWith((ref) => _TestThemeModeNotifier()),
      reinforcementSuggestionProvider.overrideWith((ref) async => homeSuggestion),
      reinforcementProgressProvider.overrideWith((ref) => _TestReinforcementProgressNotifier(reinforcementState)),
    ];
  }

  testWidgets('capture practice setup', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const PracticeSetupScreen(deckId: 'bible'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(PracticeSetupScreen),
      matchesGoldenFile('../screenshots/practice_setup.png'),
    );
  });

  testWidgets('capture deck detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const DeckDetailScreen(deckId: 'bible'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(DeckDetailScreen),
      matchesGoldenFile('../screenshots/deck_detail.png'),
    );
  });

  testWidgets('capture home mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    final homeOverrides = [
      ...buildOverrides(),
      decksProvider.overrideWith((ref) async => const <Deck>[]),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: homeOverrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('../screenshots/home_mobile_dark.png'),
    );
  });

  testWidgets('capture practice session', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    final args = ExerciseSessionArgs(
      deckId: 'bible',
      difficulty: MemorizationDifficulty.beginner,
      itemId: 'b1',
    );

    const step = ExerciseStep(
      type: ExerciseStepType.fillOptions,
      level: ExerciseLevel.level2,
      instruction: 'Completa las palabras ocultas con ayuda de opciones inteligentes.',
    );

    final debugState = ExerciseSessionState(
      queue: items,
      steps: const [
        ExerciseStep(
          type: ExerciseStepType.listen,
          instruction: 'Escucha el contenido letra por letra.',
        ),
        step,
        ExerciseStep(
          type: ExerciseStepType.reciteFromMemoryVoice,
          instruction: 'Recítalo de memoria y compara la transcripción.',
        ),
      ],
      currentItemIndex: 0,
      currentStepIndex: 1,
      difficulty: MemorizationDifficulty.beginner,
      objective: PracticeObjective.deep,
      cooperativePlayers: 1,
      cooperativeMode: CooperativeMode.solo,
      currentTurnIndex: 0,
      rescuePending: false,
      turnHandoffs: 0,
      rescueCount: 0,
      isLoading: false,
      isFinished: false,
      completedItems: const [],
      performanceSummaries: const [],
      deckId: 'bible',
      planId: 'plan_beginner',
      planName: 'Plan Principiante',
      lastEvaluation: const AnswerEvaluationResult(
        isCorrect: true,
        score: 0.78,
        mistakes: 2,
        maxMistakes: 3,
        normalizedExpected: 'porque de tal manera amo dios al mundo',
        normalizedActual: 'porque de tal manera amo dios al mundo',
        matchedWords: ['porque', 'dios', 'mundo'],
        missingWords: ['hijo'],
        feedback: 'Coincidencia dentro del margen permitido.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: ExerciseSessionScreen(
            args: args,
            debugState: debugState,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(ExerciseSessionScreen),
      matchesGoldenFile('../screenshots/practice_session.png'),
    );
  });
}

class _TestReinforcementProgressNotifier extends ReinforcementProgressNotifier {
  _TestReinforcementProgressNotifier(super.initial) : super.test();
}

class _TestThemeModeNotifier extends ThemeModeNotifier {
  _TestThemeModeNotifier() : super.test(ThemeMode.dark);
}

class _TestSmartReminderNotifier extends SmartReminderOptInNotifier {
  _TestSmartReminderNotifier(super.initial) : super.test();
}

class _TestCooperativeFollowUpNotifier extends CooperativeFollowUpNotifier {
  _TestCooperativeFollowUpNotifier(super.initial) : super.test();
}
