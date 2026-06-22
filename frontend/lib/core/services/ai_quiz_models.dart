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
    // 1. Extraer trueFalse (tolerar Map o String directa)
    final rawTrueFalse = json['trueFalse'];
    final AiTrueFalseRound trueFalseRound;
    if (rawTrueFalse is Map<String, dynamic>) {
      trueFalseRound = AiTrueFalseRound.fromJson(rawTrueFalse);
    } else if (rawTrueFalse is String && rawTrueFalse.trim().isNotEmpty) {
      final isTrueRoot = json['isTrue'];
      final derivedIsTrue = isTrueRoot is bool ? isTrueRoot : true;
      trueFalseRound = AiTrueFalseRound(
        statement: rawTrueFalse.trim(),
        isTrue: derivedIsTrue,
      );
    } else {
      throw const FormatException('La IA no devolvió un bloque "trueFalse" válido.');
    }

    // 2. Extraer multipleChoice (requiere Map)
    final rawMultipleChoice = json['multipleChoice'];
    if (rawMultipleChoice is! Map<String, dynamic>) {
      throw const FormatException('La IA no devolvió un bloque "multipleChoice" válido.');
    }
    final multipleChoiceRound = AiMultipleChoiceRound.fromJson(rawMultipleChoice);

    // 3. Extraer openQuestion (tolerar Map o String directa)
    final rawOpen = json['openQuestion'];
    final AiOpenQuestionRound openQuestionRound;
    if (rawOpen is Map<String, dynamic>) {
      openQuestionRound = AiOpenQuestionRound.fromJson(rawOpen);
    } else if (rawOpen is String && rawOpen.trim().isNotEmpty) {
      openQuestionRound = AiOpenQuestionRound(question: rawOpen.trim());
    } else {
      throw const FormatException('La IA no devolvió un bloque "openQuestion" válido.');
    }

    return AiQuizRoundSet(
      trueFalse: trueFalseRound,
      multipleChoice: multipleChoiceRound,
      openQuestion: openQuestionRound,
    );
  }
}

class AiTrueFalseRound {
  final String statement;
  final bool isTrue;

  const AiTrueFalseRound({required this.statement, required this.isTrue});

  factory AiTrueFalseRound.fromJson(Map<String, dynamic> json) {
    final statement = requireText(json, 'statement');
    final isTrueVal = json['isTrue'];
    bool isTrue = true;
    if (isTrueVal is bool) {
      isTrue = isTrueVal;
    } else if (isTrueVal is String) {
      isTrue = isTrueVal.trim().toLowerCase() == 'true';
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
    // En móvil flutter_gemma no fuerza la gramática JSON, así que el modelo a
    // veces devuelve "isCorrect" como string ("true"/"sí") o número en vez de
    // un booleano estricto. Coercionamos con tolerancia en lugar de reventar.
    final isCorrect = _coerceBool(json['isCorrect']);
    if (isCorrect == null) {
      throw const FormatException('La evaluación de la IA no trae "isCorrect".');
    }
    return AiOpenAnswerEvaluation(
      isCorrect: isCorrect,
      feedback: AiTrueFalseRound.requireText(json, 'feedback'),
    );
  }

  static bool? _coerceBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.trim().toLowerCase();
      const truthy = {'true', '1', 'sí', 'si', 'correcto', 'correcta', 'verdadero'};
      const falsy = {'false', '0', 'no', 'incorrecto', 'incorrecta', 'falso'};
      if (truthy.contains(s)) return true;
      if (falsy.contains(s)) return false;
    }
    return null;
  }
}

/// Set de versículo alterado con palabras intrusas generado por la IA local.
class IntruderVerseSet {
  final String alteredVerse;
  final List<String> intruderWords;
  final String explanation;

  const IntruderVerseSet({
    required this.alteredVerse,
    required this.intruderWords,
    required this.explanation,
  });

  factory IntruderVerseSet.fromJson(Map<String, dynamic> json) {
    final alteredVerse = AiTrueFalseRound.requireText(json, 'alteredVerse');
    final explanation = AiTrueFalseRound.requireText(json, 'explanation');
    final rawIntruderWords = json['intruderWords'];
    if (rawIntruderWords is! List) {
      throw const FormatException('El ejercicio no trae la lista de palabras intrusas.');
    }
    final intruderWords = rawIntruderWords
        .map((w) => w.toString().trim())
        .where((w) => w.isNotEmpty)
        .toList();
    if (intruderWords.isEmpty) {
      throw const FormatException('La lista de palabras intrusas está vacía.');
    }
    return IntruderVerseSet(
      alteredVerse: alteredVerse,
      intruderWords: intruderWords,
      explanation: explanation,
    );
  }
}

