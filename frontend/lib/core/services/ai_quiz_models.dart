/// Modelos del set de preguntas generado por la IA local para el quiz.
/// La IA devuelve JSON validado por esquema; estos `fromJson` añaden la
/// validación defensiva final (trim + campos no vacíos).
class AiQuizRoundSet {
  final AiTrueFalseRound trueFalse;
  final AiMultipleChoiceRound multipleChoice;
  final AiOpenQuestionRound openQuestion;

  const AiQuizRoundSet({
    required this.trueFalse,
    required this.multipleChoice,
    required this.openQuestion,
  });

  factory AiQuizRoundSet.fromJson(Map<String, dynamic> json) {
    return AiQuizRoundSet(
      trueFalse: AiTrueFalseRound.fromJson(_requireMap(json, 'trueFalse')),
      multipleChoice:
          AiMultipleChoiceRound.fromJson(_requireMap(json, 'multipleChoice')),
      openQuestion:
          AiOpenQuestionRound.fromJson(_requireMap(json, 'openQuestion')),
    );
  }

  static Map<String, dynamic> _requireMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    throw FormatException('La IA no devolvió el bloque "$key".');
  }
}

class AiTrueFalseRound {
  final String statement;
  final bool isTrue;

  const AiTrueFalseRound({required this.statement, required this.isTrue});

  factory AiTrueFalseRound.fromJson(Map<String, dynamic> json) {
    final statement = requireText(json, 'statement');
    final isTrue = json['isTrue'];
    if (isTrue is! bool) {
      throw const FormatException('La afirmación V/F no trae "isTrue".');
    }
    return AiTrueFalseRound(statement: statement, isTrue: isTrue);
  }

  static String requireText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('La IA devolvió "$key" vacío.');
  }
}

class AiMultipleChoiceRound {
  static const int requiredDistractorCount = 3;

  final String question;
  final String correct;
  final List<String> distractors;

  const AiMultipleChoiceRound({
    required this.question,
    required this.correct,
    required this.distractors,
  });

  factory AiMultipleChoiceRound.fromJson(Map<String, dynamic> json) {
    final question = AiTrueFalseRound.requireText(json, 'question');
    final correct = AiTrueFalseRound.requireText(json, 'correct');
    final rawDistractors = json['distractors'];
    if (rawDistractors is! List) {
      throw const FormatException('La pregunta de opción múltiple no trae distractores.');
    }
    final distractors = rawDistractors
        .map((distractor) => distractor.toString().trim())
        .where((distractor) => distractor.isNotEmpty && distractor != correct)
        .toList();
    if (distractors.length < requiredDistractorCount) {
      throw const FormatException('La IA devolvió menos de 3 distractores válidos.');
    }
    return AiMultipleChoiceRound(
      question: question,
      correct: correct,
      distractors: distractors.take(requiredDistractorCount).toList(),
    );
  }
}

class AiOpenQuestionRound {
  final String question;

  const AiOpenQuestionRound({required this.question});

  factory AiOpenQuestionRound.fromJson(Map<String, dynamic> json) {
    return AiOpenQuestionRound(
      question: AiTrueFalseRound.requireText(json, 'question'),
    );
  }
}

/// Veredicto de la IA local sobre una respuesta abierta del usuario.
class AiOpenAnswerEvaluation {
  final bool isCorrect;
  final String feedback;

  const AiOpenAnswerEvaluation({
    required this.isCorrect,
    required this.feedback,
  });

  factory AiOpenAnswerEvaluation.fromJson(Map<String, dynamic> json) {
    final isCorrect = json['isCorrect'];
    if (isCorrect is! bool) {
      throw const FormatException('La evaluación de la IA no trae "isCorrect".');
    }
    return AiOpenAnswerEvaluation(
      isCorrect: isCorrect,
      feedback: AiTrueFalseRound.requireText(json, 'feedback'),
    );
  }
}
