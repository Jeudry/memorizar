class AnswerEvaluationResult {
  const AnswerEvaluationResult({
    required this.isCorrect,
    required this.score,
    required this.mistakes,
    required this.maxMistakes,
    required this.normalizedExpected,
    required this.normalizedActual,
    required this.matchedWords,
    required this.missingWords,
    required this.feedback,
  });

  final bool isCorrect;
  final double score;
  final int mistakes;
  final int maxMistakes;
  final String normalizedExpected;
  final String normalizedActual;
  final List<String> matchedWords;
  final List<String> missingWords;
  final String feedback;
}
