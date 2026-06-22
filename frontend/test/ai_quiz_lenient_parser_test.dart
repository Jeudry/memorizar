import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/ai_quiz_models.dart';

/// Tests del parser tolerante `AiQuizRoundSet.lenient` con las formas REALES que
/// el modelo Gemma on-device devolvió (capturadas del log del dispositivo) y que
/// antes hacían fallar la generación del quiz. No requieren modelo ni servidor.
void main() {
  group('AiQuizRoundSet.lenient', () {
    test('objeto keyed estándar {trueFalse, multipleChoice, openQuestion}', () {
      final decoded = jsonDecode('''
        {
          "trueFalse": {"statement": "Génesis 1:1 afirma que Dios creó el cielo y la tierra.", "isTrue": true},
          "multipleChoice": {
            "question": "¿Qué se describe en Génesis 1:1?",
            "correct": "La creación del cielo y la tierra",
            "distractors": ["La creación de la luz", "El diluvio", "El éxodo"]
          },
          "openQuestion": {"question": "Explica el significado del versículo."}
        }
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      expect(set.trueFalse.statement, isNotEmpty);
      expect(set.trueFalse.isTrue, isTrue);
      expect(set.multipleChoice.correct, 'La creación del cielo y la tierra');
      expect(set.multipleChoice.distractors, hasLength(3));
      expect(set.openQuestion.question, isNotEmpty);
    });

    test('ARRAY con un set completo por versículo (reparte uno por texto)', () {
      final decoded = jsonDecode('''
        [
          {
            "trueFalse": {"statement": "Afirmación sobre Génesis 1:1.", "isTrue": false},
            "multipleChoice": {"question": "P1", "correct": "C1", "distractors": ["a","b","c"]},
            "openQuestion": {"question": "Abierta 1"}
          },
          {
            "trueFalse": {"statement": "Afirmación sobre Génesis 1:2.", "isTrue": false},
            "multipleChoice": {"question": "P2", "correct": "C2", "distractors": ["d","e","f"]},
            "openQuestion": {"question": "Abierta 2"}
          }
        ]
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      // V/F del 1er set, opción múltiple del 2º, abierta del 3º (2%2 -> 1er).
      expect(set.trueFalse.statement, contains('1:1'));
      expect(set.multipleChoice.question, 'P2');
      expect(set.openQuestion.question, 'Abierta 1');
    });

    test('{questions:[{type,...}]} con campo "question" y answer booleano', () {
      final decoded = jsonDecode('''
        {
          "questions": [
            {"text_id": "Génesis 1:1", "type": "trueFalse", "question": "Afirmación V/F.", "answer": false},
            {"type": "multipleChoice", "question": "¿Cuál describe el estado inicial?",
             "correct": "Sin forma y vacía", "distractors": ["Formada", "Luminosa", "Poblada", "Ordenada"]},
            {"type": "openQuestion", "question": "Explica brevemente.", "prompt": "En pocas palabras"}
          ]
        }
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      expect(set.trueFalse.statement, 'Afirmación V/F.');
      expect(set.trueFalse.isTrue, isFalse);
      expect(set.multipleChoice.correct, 'Sin forma y vacía');
      expect(set.multipleChoice.distractors, hasLength(3)); // recorta 4 -> 3
      expect(set.openQuestion.question, 'Explica brevemente.');
    });

    test('{questions:[{type,...}]} con campo "text" y answer string "false"', () {
      final decoded = jsonDecode('''
        {
          "questions": [
            {"type": "trueFalse", "text": "La tierra tenía forma definida.", "answer": "false"},
            {"type": "multipleChoice", "text": "¿Cómo era la tierra?",
             "correct": "Sin forma y vacía", "distractors": ["Formada", "Llena de luz"]},
            {"type": "openQuestion", "text": "¿Qué implica 'sin forma y vacía'?",
             "expected_answer_keywords": ["potencialidad", "orden"]}
          ]
        }
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      expect(set.trueFalse.statement, 'La tierra tenía forma definida.');
      expect(set.trueFalse.isTrue, isFalse);
      expect(set.multipleChoice.question, '¿Cómo era la tierra?');
      expect(set.multipleChoice.distractors, isNotEmpty);
      expect(set.openQuestion.question, contains('sin forma'));
    });

    test('array de preguntas tipadas sin envoltura', () {
      final decoded = jsonDecode('''
        [
          {"type": "openQuestion", "question": "Abierta."},
          {"type": "trueFalse", "statement": "V/F.", "isTrue": true},
          {"type": "multipleChoice", "question": "MC.", "correct": "ok", "distractors": ["x","y","z"]}
        ]
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      // El orden de las secciones se resuelve por tipo, no por posición.
      expect(set.trueFalse.statement, 'V/F.');
      expect(set.multipleChoice.question, 'MC.');
      expect(set.openQuestion.question, 'Abierta.');
    });

    test('opción múltiple cuyo distractor repite la correcta la descarta', () {
      final decoded = jsonDecode('''
        {
          "trueFalse": {"statement": "V/F.", "isTrue": true},
          "multipleChoice": {"question": "MC.", "correct": "ok", "distractors": ["ok", "malo1", "malo2", "malo3"]},
          "openQuestion": {"question": "Abierta."}
        }
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      expect(set.multipleChoice.distractors, isNot(contains('ok')));
      expect(set.multipleChoice.distractors, hasLength(3));
    });
  });
}
