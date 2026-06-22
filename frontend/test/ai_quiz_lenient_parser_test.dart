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

    test('{questions:[{trueFalse:{}},{multipleChoice:{}},{openQuestion:{}}]} híbrido', () {
      // Forma real del dispositivo: questions con un wrapper keyed por elemento.
      final decoded = jsonDecode('''
        {
          "questions": [
            {"trueFalse": {"statement": "Génesis 1:1 afirma que Dios creó todo.", "isTrue": false}},
            {"multipleChoice": {"question": "¿Estado inicial de la tierra?",
              "correct": "Sin forma y vacía", "distractors": ["Perfecta", "Llena de vida", "Con luz"]}},
            {"openQuestion": {"question": "Explica la acción de Dios.", "answer_guideline": "Dios es el agente creador."}}
          ]
        }
      ''');
      final set = AiQuizRoundSet.lenient(decoded);
      expect(set.trueFalse.statement, contains('Dios creó'));
      expect(set.trueFalse.isTrue, isFalse);
      expect(set.multipleChoice.correct, 'Sin forma y vacía');
      expect(set.multipleChoice.distractors, hasLength(3));
      expect(set.openQuestion.question, 'Explica la acción de Dios.');
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

  group('AiOpenAnswerEvaluation.lenient', () {
    test('forma estándar {isCorrect, feedback}', () {
      final decoded = jsonDecode('{"isCorrect": true, "feedback": "Bien explicado."}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isTrue);
      expect(ev.feedback, 'Bien explicado.');
    });

    test('isCorrect como string y feedback bajo "explanation"', () {
      final decoded =
          jsonDecode('{"isCorrect": "false", "explanation": "No se relaciona con el versículo."}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isFalse);
      expect(ev.feedback, contains('versículo'));
    });

    test('claves alternativas {correct, reason}', () {
      final decoded = jsonDecode('{"correct": true, "reason": "Correcto."}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isTrue);
      expect(ev.feedback, 'Correcto.');
    });

    test('veredicto textual {verdict:"incorrect"} sin booleano', () {
      final decoded = jsonDecode('{"verdict": "incorrect", "comentario": "Respuesta vacía."}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isFalse);
      expect(ev.feedback, 'Respuesta vacía.');
    });

    test('score numérico decide el veredicto', () {
      final decoded = jsonDecode('{"score": 0.8, "feedback": "Buena respuesta."}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isTrue);
    });

    test('wrapper {evaluation:{...}} se desenvuelve', () {
      final decoded = jsonDecode('{"evaluation": {"isCorrect": false, "feedback": "Mal."}}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isFalse);
      expect(ev.feedback, 'Mal.');
    });

    test('feedback ausente usa un valor por defecto en vez de fallar', () {
      final decoded = jsonDecode('{"isCorrect": true}');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isTrue);
      expect(ev.feedback, isNotEmpty);
    });

    test('array con un único objeto de evaluación', () {
      final decoded = jsonDecode('[{"isCorrect": true, "feedback": "Ok."}]');
      final ev = AiOpenAnswerEvaluation.lenient(decoded);
      expect(ev.isCorrect, isTrue);
      expect(ev.feedback, 'Ok.');
    });
  });

  group('IntruderVerseSet.lenient', () {
    test('forma estándar', () {
      final decoded = jsonDecode(
          '{"alteredVerse": "En el comienzo creó Dios el cielo y la tierra.", "intruderWords": ["comienzo"], "explanation": "El original dice principio."}');
      final s = IntruderVerseSet.lenient(decoded);
      expect(s.alteredVerse, contains('comienzo'));
      expect(s.intruderWords, contains('comienzo'));
      expect(s.explanation, isNotEmpty);
    });

    test('claves alternativas (versiculoAlterado, intrusos) y explicación ausente', () {
      final decoded = jsonDecode(
          '{"versiculoAlterado": "Todo lo puedo en Cristo que me anima.", "intrusos": ["anima"]}');
      final s = IntruderVerseSet.lenient(decoded);
      expect(s.alteredVerse, contains('anima'));
      expect(s.intruderWords, contains('anima'));
      expect(s.explanation, isNotEmpty); // default
    });

    test('intruderWords como string separada por comas', () {
      final decoded = jsonDecode(
          '{"alteredVerse": "texto alterado", "intruderWords": "anima, fuerza", "explanation": "x"}');
      final s = IntruderVerseSet.lenient(decoded);
      expect(s.intruderWords, containsAll(['anima', 'fuerza']));
    });

    test('wrapper {result:{...}}', () {
      final decoded = jsonDecode(
          '{"result": {"alteredVerse": "v", "intruderWords": ["a"], "explanation": "e"}}');
      final s = IntruderVerseSet.lenient(decoded);
      expect(s.alteredVerse, 'v');
      expect(s.intruderWords, ['a']);
    });
  });
}
