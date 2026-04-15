import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/practice/services/text_normalizer_service.dart';

class UnderstandingQuestionChallenge {
  const UnderstandingQuestionChallenge({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
}

class UnderstandingExerciseService {
  const UnderstandingExerciseService(this._normalizer);

  final TextNormalizerService _normalizer;

  UnderstandingQuestionChallenge buildQuestion({
    required Item item,
    required List<Item> deckItems,
  }) {
    final tokens = _normalizer.tokenize(item.back).where((token) => token.length > 3).toList();
    final keyWord = tokens.isEmpty ? item.front : tokens.first;

    if (item.book != null && item.chapter != null && item.verse != null) {
      final options = {
        item.front,
        ...deckItems.where((candidate) => candidate.id != item.id).map((candidate) => candidate.front).take(3),
      }.take(4).toList();
      return UnderstandingQuestionChallenge(
        question: '¿A qué referencia pertenece este contenido?',
        options: options,
        correctAnswer: item.front,
        explanation: 'Relacionar el contenido con su referencia ayuda a fijar contexto y significado.',
      );
    }

    final summaries = {
      'Habla principalmente de "$keyWord".',
      ...deckItems
          .where((candidate) => candidate.id != item.id)
          .map((candidate) {
            final candidateTokens = _normalizer.tokenize(candidate.back).where((token) => token.length > 3).toList();
            final candidateWord = candidateTokens.isEmpty ? candidate.front : candidateTokens.first;
            return 'Habla principalmente de "$candidateWord".';
          })
          .take(3),
    }.take(4).toList();

    return UnderstandingQuestionChallenge(
      question: '¿Cuál opción refleja mejor la idea central del contenido?',
      options: summaries,
      correctAnswer: 'Habla principalmente de "$keyWord".',
      explanation: 'Entender la idea central facilita recordar el contenido completo.',
    );
  }
}
