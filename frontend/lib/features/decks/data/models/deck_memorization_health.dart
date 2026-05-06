import 'package:memorizar/features/home/data/models/reinforcement_suggestion.dart';

class DeckMemorizationHealth {
  const DeckMemorizationHealth({
    required this.healthScore,
    required this.statusLabel,
    required this.summary,
    required this.primaryRoute,
    required this.exerciseAverageScore,
    required this.cardsAverageScore,
    this.secondaryRoute,
  });

  final double healthScore;
  final String statusLabel;
  final String summary;
  final ReinforcementRouteStep primaryRoute;
  final ReinforcementRouteStep? secondaryRoute;
  final double? exerciseAverageScore;
  final double? cardsAverageScore;
}
