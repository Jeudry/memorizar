import 'package:go_router/go_router.dart';
import 'package:memorizar/features/home/presentation/screens/home_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/decks_screen.dart';
import 'package:memorizar/features/decks/presentation/screens/deck_detail_screen.dart';
import 'package:memorizar/features/review/presentation/screens/review_screen.dart';
import 'package:memorizar/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:memorizar/features/shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
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
      path: '/decks/:deckId',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return DeckDetailScreen(deckId: deckId);
      },
    ),
    GoRoute(
      path: '/review/:deckId',
      builder: (context, state) {
        final deckId = state.pathParameters['deckId']!;
        return ReviewScreen(deckId: deckId);
      },
    ),
  ],
);
