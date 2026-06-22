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

  /// Parser tolerante: el modelo on-device (sin gramática forzada en móvil)
  /// devuelve formas muy variadas — objeto keyed {trueFalse, multipleChoice,
  /// openQuestion}, array de esos sets, `{ "questions": [ {type:...}, ... ] }`,
  /// o un array de preguntas tipadas — con nombres de campo inconsistentes
  /// (question/text/statement, answer/isTrue, distractors/options). Esto extrae
  /// las 3 preguntas de cualquiera de esas formas en vez de reventar.
  factory AiQuizRoundSet.lenient(dynamic decoded) {
    final questions = _collectQuestions(decoded);
    if (questions.isEmpty) {
      throw const FormatException('La IA no devolvió preguntas de quiz.');
    }

    Map<String, dynamic>? tf, mc, oq;
    for (final q in questions) {
      final type = (q['type'] ?? q['questionType'] ?? '').toString().toLowerCase();
      final hasDistractors = q['distractors'] is List || q['options'] is List;
      final hasBoolAnswer = _llmBool(q['isTrue'] ?? q['answer'] ?? q['is_true']) != null &&
          !hasDistractors;
      if (mc == null &&
          (type.contains('multiple') || type.contains('choice') ||
              type.contains('opcion') || type.contains('opción') || hasDistractors)) {
        mc = q;
      } else if (tf == null &&
          (type.contains('true') || type.contains('false') ||
              type.contains('verdadero') || type.contains('falso') || hasBoolAnswer)) {
        tf = q;
      } else if (oq == null &&
          (type.contains('open') || type.contains('abierta') || type.contains('open_question'))) {
        oq = q;
      }
    }

    // Rellenar las que falten por orden posicional con las preguntas sobrantes.
    final leftovers = questions.where((q) => q != tf && q != mc && q != oq).toList();
    tf ??= leftovers.isNotEmpty ? leftovers.removeAt(0) : null;
    mc ??= leftovers.isNotEmpty ? leftovers.removeAt(0) : null;
    oq ??= leftovers.isNotEmpty ? leftovers.removeAt(0) : null;

    if (tf == null || mc == null || oq == null) {
      throw const FormatException('La IA no devolvió las 3 preguntas del quiz.');
    }

    return AiQuizRoundSet(
      trueFalse: _trueFalseLenient(tf),
      multipleChoice: _multipleChoiceLenient(mc),
      openQuestion: _openLenient(oq),
    );
  }

  /// Aplana cualquier envoltura a una lista de mapas-pregunta tipados.
  static List<Map<String, dynamic>> _collectQuestions(dynamic decoded) {
    if (decoded is List) {
      final maps = decoded.whereType<Map<String, dynamic>>().toList();
      if (maps.any((m) =>
          m.containsKey('trueFalse') ||
          m.containsKey('multipleChoice') ||
          m.containsKey('openQuestion'))) {
        return _fromKeyedSets(maps);
      }
      return maps;
    }
    if (decoded is Map<String, dynamic>) {
      for (final key in const ['questions', 'preguntas', 'items', 'quiz']) {
        final v = decoded[key];
        if (v is List) {
          final maps = v.whereType<Map<String, dynamic>>().toList();
          if (maps.isNotEmpty) return maps;
        }
      }
      if (decoded.containsKey('trueFalse') ||
          decoded.containsKey('multipleChoice') ||
          decoded.containsKey('openQuestion')) {
        return _fromKeyedSets([decoded]);
      }
      if (decoded.containsKey('type')) return [decoded];
    }
    throw const FormatException('Estructura de quiz no reconocida.');
  }

  /// Convierte uno o más sets keyed en 3 preguntas tipadas, repartiendo una
  /// sección por set (con módulo) para cubrir todos los textos del grupo.
  static List<Map<String, dynamic>> _fromKeyedSets(List<Map<String, dynamic>> sets) {
    final n = sets.length;
    Map<String, dynamic> section(int i, String key) {
      final parent = sets[i % n];
      final raw = parent[key];
      final m = raw is Map<String, dynamic>
          ? Map<String, dynamic>.of(raw)
          : <String, dynamic>{'question': raw?.toString() ?? ''};
      m['type'] = key;
      if (key == 'trueFalse' && m['isTrue'] == null && parent['isTrue'] != null) {
        m['isTrue'] = parent['isTrue'];
      }
      return m;
    }

    return [
      section(0, 'trueFalse'),
      section(1, 'multipleChoice'),
      section(2, 'openQuestion'),
    ];
  }

  static AiTrueFalseRound _trueFalseLenient(Map<String, dynamic> q) {
    final statement =
        _llmText(q, const ['statement', 'question', 'text', 'affirmation', 'afirmacion']);
    if (statement == null) {
      throw const FormatException('La IA no devolvió un enunciado de verdadero/falso.');
    }
    final isTrue = _llmBool(q['isTrue'] ?? q['answer'] ?? q['correct'] ?? q['is_true']) ?? true;
    return AiTrueFalseRound(statement: statement, isTrue: isTrue);
  }

  static AiMultipleChoiceRound _multipleChoiceLenient(Map<String, dynamic> q) {
    final question = _llmText(q, const ['question', 'text', 'statement']);
    if (question == null) {
      throw const FormatException('La IA no devolvió la pregunta de opción múltiple.');
    }
    var correct = _llmText(q, const ['correct', 'answer', 'correctAnswer', 'correcta']);
    var distractors =
        _llmStringList(q['distractors'] ?? q['options'] ?? q['opciones'] ?? q['incorrect']);
    if (correct != null) {
      distractors = distractors.where((d) => d != correct).toList();
    } else if (distractors.isNotEmpty) {
      // 'options' sin 'correct' explícita: asumir la primera como correcta.
      correct = distractors.removeAt(0);
    }
    if (correct == null) {
      throw const FormatException('La IA no devolvió la respuesta correcta de opción múltiple.');
    }
    if (distractors.isEmpty) {
      throw const FormatException('La IA no devolvió distractores de opción múltiple.');
    }
    return AiMultipleChoiceRound(
      question: question,
      correct: correct,
      distractors: distractors.take(AiMultipleChoiceRound.requiredDistractorCount).toList(),
    );
  }

  static AiOpenQuestionRound _openLenient(Map<String, dynamic> q) {
    final question = _llmText(q, const ['question', 'text', 'prompt', 'statement']);
    if (question == null) {
      throw const FormatException('La IA no devolvió la pregunta abierta.');
    }
    return AiOpenQuestionRound(question: question);
  }
}

/// Primer string no vacío entre [keys].
String? _llmText(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// Lista de strings no vacíos (tolera elementos no-string).
List<String> _llmStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Coerción tolerante a bool desde bool/num/string ("true"/"sí"/"falso"…).
bool? _llmBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.trim().toLowerCase();
    const truthy = {'true', '1', 'sí', 'si', 'correcto', 'correcta', 'verdadero', 'verdad'};
    const falsy = {'false', '0', 'no', 'incorrecto', 'incorrecta', 'falso'};
    if (truthy.contains(s)) return true;
    if (falsy.contains(s)) return false;
  }
  return null;
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
    final isCorrect = _llmBool(json['isCorrect']);
    if (isCorrect == null) {
      throw const FormatException('La evaluación de la IA no trae "isCorrect".');
    }
    return AiOpenAnswerEvaluation(
      isCorrect: isCorrect,
      feedback: AiTrueFalseRound.requireText(json, 'feedback'),
    );
  }

  /// Parser tolerante para la evaluación: igual que el quiz, en móvil el modelo
  /// no sigue una estructura fija. Acepta el veredicto bajo muchas claves
  /// (isCorrect/correct/valid/aprobado…), derivado de un veredicto textual
  /// ("correcto"/"incorrecto") o de un score numérico, desenvuelve wrappers
  /// comunes ({"evaluation": {...}}) y el feedback bajo varias claves (con un
  /// valor por defecto si falta, porque no es crítico).
  factory AiOpenAnswerEvaluation.lenient(dynamic decoded) {
    Map<String, dynamic>? map;
    if (decoded is List) {
      final maps = decoded.whereType<Map<String, dynamic>>().toList();
      map = maps.isEmpty ? null : maps.first;
    } else if (decoded is Map<String, dynamic>) {
      map = decoded;
    }
    if (map == null) {
      throw const FormatException('La evaluación no es un objeto JSON.');
    }

    // Desenvolver wrappers comunes.
    for (final key in const [
      'evaluation', 'evaluacion', 'evaluación', 'result', 'resultado', 'response'
    ]) {
      final inner = map![key];
      if (inner is Map<String, dynamic>) {
        map = inner;
        break;
      }
    }

    bool? isCorrect = _llmBool(map!['isCorrect'] ??
        map['correct'] ??
        map['is_correct'] ??
        map['isValid'] ??
        map['valid'] ??
        map['aprobado'] ??
        map['approved'] ??
        map['passed'] ??
        map['esCorrecta'] ??
        map['correcta'] ??
        map['acierto']);

    // Derivar de un veredicto textual (chequear lo negativo primero porque
    // "incorrecto" contiene "correcto").
    if (isCorrect == null) {
      final verdict = _llmText(map, const [
        'verdict', 'veredicto', 'result', 'resultado', 'evaluation', 'status', 'estado'
      ])?.toLowerCase();
      if (verdict != null) {
        if (verdict.contains('incorrect') || verdict.contains('inválid') ||
            verdict.contains('invalid') || verdict.contains('rechaz') ||
            verdict.contains('fallo') || verdict == 'mal') {
          isCorrect = false;
        } else if (verdict.contains('correct') || verdict.contains('aprob') ||
            verdict.contains('válid') || verdict.contains('valid') ||
            verdict.contains('bien') || verdict.contains('acept')) {
          isCorrect = true;
        }
      }
    }

    // Derivar de un score numérico (0..1 o 0..100).
    if (isCorrect == null) {
      final score = map['score'] ?? map['puntaje'] ?? map['puntuacion'] ?? map['rating'];
      if (score is num) isCorrect = score >= (score > 1 ? 50 : 0.5);
    }

    if (isCorrect == null) {
      throw const FormatException('La evaluación no indica si la respuesta es correcta.');
    }

    final feedback = _llmText(map, const [
          'feedback', 'explanation', 'explicacion', 'explicación', 'reason', 'razon',
          'razón', 'justification', 'justificacion', 'justificación', 'comment',
          'comentario', 'message', 'mensaje', 'retroalimentacion', 'retroalimentación',
        ]) ??
        (isCorrect ? '¡Respuesta correcta!' : 'Respuesta no válida. Inténtalo de nuevo.');

    return AiOpenAnswerEvaluation(isCorrect: isCorrect, feedback: feedback);
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

