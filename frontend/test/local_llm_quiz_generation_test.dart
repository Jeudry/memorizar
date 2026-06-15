import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/llama_server_manager.dart';
import 'package:frontend/core/services/local_llm_service.dart';

/// Test de integración contra el motor llama.cpp local real.
/// Requiere un `llama-server` sano en el puerto fijo (el que la app levanta);
/// si no está disponible se omite para no romper CI sin GPU/modelo.
/// Nota: sin TestWidgetsFlutterBinding a propósito — su HttpClient mockeado
/// devolvería 400 a las llamadas reales al motor local.
void main() {
  Future<bool> engineAvailable() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      final response =
          await dio.get('${LlamaServerManager.instance.baseUrl}/health');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  test(
    'generateQuizRoundSet devuelve preguntas reales y variadas del modelo',
    () async {
      final available = await engineAvailable();
      if (!available) {
        markTestSkipped('llama-server no está corriendo; test omitido.');
        return;
      }

      final service = LocalLlmService.instance;
      const reference = 'Filipenses 4:13';
      const verse = 'Todo lo puedo en Cristo que me fortalece.';

      final first = await service.generateQuizRoundSet(
        reference: reference,
        verseText: verse,
        advanced: false,
      );

      expect(first.trueFalse.statement, isNotEmpty);
      expect(first.multipleChoice.question, isNotEmpty);
      expect(first.multipleChoice.correct, isNotEmpty);
      expect(first.multipleChoice.distractors, hasLength(3));
      expect(
        first.multipleChoice.distractors,
        isNot(contains(first.multipleChoice.correct)),
      );
      expect(first.openQuestion.question, isNotEmpty);

      final second = await service.generateQuizRoundSet(
        reference: reference,
        verseText: verse,
        advanced: false,
      );

      final identicalSets = first.trueFalse.statement ==
              second.trueFalse.statement &&
          first.multipleChoice.question == second.multipleChoice.question &&
          first.openQuestion.question == second.openQuestion.question;
      expect(
        identicalSets,
        isFalse,
        reason: 'Dos generaciones seguidas no deben producir el mismo set; '
            'las preguntas tienen que variar en cada entrada.',
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'evaluateOpenAnswer aprueba una respuesta coherente y rechaza una vacía de contenido',
    () async {
      final available = await engineAvailable();
      if (!available) {
        markTestSkipped('llama-server no está corriendo; test omitido.');
        return;
      }

      final service = LocalLlmService.instance;
      const verse = 'Todo lo puedo en Cristo que me fortalece.';
      const question = '¿Qué significa este versículo para tu vida diaria?';

      final goodEvaluation = await service.evaluateOpenAnswer(
        question: question,
        verseText: verse,
        userAnswer:
            'Que con la fuerza que me da Cristo puedo enfrentar cualquier dificultad.',
      );
      expect(goodEvaluation.isCorrect, isTrue);
      expect(goodEvaluation.feedback, isNotEmpty);

      final badEvaluation = await service.evaluateOpenAnswer(
        question: question,
        verseText: verse,
        userAnswer: 'no se me ocurre nada de futbol hoy',
      );
      expect(badEvaluation.isCorrect, isFalse);
      expect(badEvaluation.feedback, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
