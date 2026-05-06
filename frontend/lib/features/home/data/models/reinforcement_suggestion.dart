class ReinforcementSuggestion {
  const ReinforcementSuggestion({
    required this.deckId,
    required this.deckName,
    required this.modeLabel,
    required this.reason,
    required this.ctaLabel,
    required this.primaryRoute,
    this.secondaryRoute,
    this.weakestExerciseLabel,
    this.daysSinceLastPractice,
  });

  final String deckId;
  final String deckName;
  final String modeLabel;
  final String reason;
  final String ctaLabel;
  final ReinforcementRouteStep primaryRoute;
  final ReinforcementRouteStep? secondaryRoute;
  final String? weakestExerciseLabel;
  final int? daysSinceLastPractice;
}

class ReinforcementRouteStep {
  const ReinforcementRouteStep({
    required this.label,
    required this.routePath,
    required this.description,
  });

  final String label;
  final String routePath;
  final String description;
}
