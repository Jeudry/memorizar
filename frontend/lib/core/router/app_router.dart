import 'package:go_router/go_router.dart';
import 'package:memorizar/features/home/presentation/screens/home_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/decks_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/deck_detail_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/deck_form_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/item_edit_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/item_form_screen.dart';
import 'package:memorizar/features/cards/presentation/screens/cards_session_screen.dart';
import 'package:memorizar/features/cards/presentation/screens/cards_setup_screen.dart';
import 'package:memorizar/features/review/presentation/screens/review_screen.dart';
import 'package:memorizar/features/practice/data/models/exercise_session_args.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/presentation/screens/exercise_session_screen.dart';
import 'package:memorizar/features/practice/presentation/screens/practice_setup_screen.dart';
import 'package:memorizar/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:memorizar/features/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set in main() before runApp().
late SharedPreferences globalPrefs;

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  redirect: (context, state) {
    if (state.uri.path == '/onboarding') return null;
    final completed = globalPrefs.getBool('memorizar_onboarding_done') ?? false;
    if (!completed) return '/onboarding';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/decks',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DecksScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/decks/new',
      builder: (context, state) => const DeckFormScreen(),
    ),
    GoRoute(
      path: '/decks/:deckId',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return DeckDetailScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/edit',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return DeckFormScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/items/:itemId',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        final itemId = state.pathParameters['itemId']!;
        return ItemEditScreen(deckId: deckId, itemId: itemId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/items/new',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return ItemFormScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/review/:deckId',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return ReviewScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/practice',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return PracticeSetupScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/cards',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return CardsSetupScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/cards/session',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return CardsSessionScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/decks/:deckId/practice/session',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        final difficulty = MemorizationDifficulty.values.firstWhere(
          (value) => value.name == state.uri.queryParameters['difficulty'],
          orElse: () => MemorizationDifficulty.beginner,
        );
        final objective = PracticeObjective.values.firstWhere(
          (value) => value.name == state.uri.queryParameters['objective'],
          orElse: () => PracticeObjective.deep,
        );
        final cooperativeMode = CooperativeMode.values.firstWhere(
          (value) => value.name == state.uri.queryParameters['coopMode'],
          orElse: () => CooperativeMode.solo,
        );
        return ExerciseSessionScreen(
          args: ExerciseSessionArgs(
            deckId: deckId,
            difficulty: difficulty,
            objective: objective,
            planId: state.uri.queryParameters['planId'],
            itemId: state.uri.queryParameters['itemId'],
            weakOnly: state.uri.queryParameters['weakOnly'] == 'true',
            cooperativePlayers: int.tryParse(state.uri.queryParameters['coop'] ?? '') ?? 1,
            cooperativeMode: cooperativeMode,
          ),
        );
      },
    ),
  ],
);
