import 'package:memorizar/features/practice/data/models/exercise_performance_summary.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';

class PracticeCoachService {
  const PracticeCoachService();

  String buildCoachFeedback({
    required List<ExercisePerformanceSummary> summaries,
    required PracticeObjective objective,
    double? recentExerciseAverage,
    double? recentCardsAverage,
    int? daysSincePractice,
  }) {
    if (summaries.isEmpty) {
      final modeBalance = recentCardsAverage != null && recentExerciseAverage != null
          ? recentCardsAverage < recentExerciseAverage - 0.1
              ? 'Conviene volver un momento a cards antes de exigir cierre profundo.'
              : recentExerciseAverage < recentCardsAverage - 0.1
                  ? 'Conviene volver a ejercicios para que el contenido salga más limpio.'
                  : 'Por ahora puedes sostener una sesión mixta sin problema.'
          : 'Todavía no hay datos suficientes. Una sesión más nos dará una recomendación mejor.';
      final recency = daysSincePractice != null && daysSincePractice >= 4
          ? 'Llevas varios días sin practicar, así que mejor volver con una sesión corta.'
          : 'La señal todavía es temprana, pero ya podemos sugerir una siguiente vuelta razonable.';
      return '$modeBalance $recency';
    }

    final weakest = summaries.first;
    final strongest = summaries.last;
    final focus = switch (objective) {
      PracticeObjective.quick => 'mantener ritmo',
      PracticeObjective.deep => 'profundizar memoria',
      PracticeObjective.duel => 'superar tu mejor marca',
      PracticeObjective.totalExam => 'cerrar sin ayudas',
      PracticeObjective.master => 'rendir al máximo bajo presión',
    };
    final nextAction = _nextActionFor(weakest.type, objective);
    final rhythmNote = daysSincePractice == null
        ? 'Vienes con señal reciente suficiente para afinar la siguiente vuelta.'
        : daysSincePractice >= 4
            ? 'Además, hubo una pausa larga: conviene reacondicionar memoria antes de exigir cierre perfecto.'
            : 'El ritmo sigue vivo, así que vale la pena apretar un poco más donde estás flojo.';
    final modeBalance = recentCardsAverage != null && recentExerciseAverage != null
        ? recentCardsAverage < recentExerciseAverage - 0.1
            ? 'Tu lectura general del bloque va por detrás de tu memoria profunda.'
            : recentExerciseAverage < recentCardsAverage - 0.1
                ? 'Tu memoria general está mejor que tu cierre profundo.'
                : 'Cards y ejercicios vienen bastante alineados.'
        : 'Todavía falta más historial para comparar cards y ejercicios con precisión.';

    return 'Tu foco fue $focus. Lo más flojo salió en ${weakest.type.label.toLowerCase()} y lo más sólido en ${strongest.type.label.toLowerCase()}. $modeBalance $rhythmNote Siguiente paso recomendado: $nextAction';
  }

  String buildVoiceFeedback({
    required String? transcript,
    required double? score,
  }) {
    final length = transcript?.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length ?? 0;
    if (score == null) {
      return 'Aún no hay análisis de voz disponible para esta sesión.';
    }
    if (score >= 0.85) {
      return 'La voz salió firme: buena continuidad y coincidencia alta${length > 0 ? ' con $length palabras detectadas' : ''}.';
    }
    if (score >= 0.65) {
      return 'La recitación fue usable, pero hubo cortes o sustituciones. Vale la pena repetir el cierre una vez más.';
    }
    return 'La detección de voz tuvo demasiadas pérdidas. Prueba un tramo más corto o vuelve a escuchar antes del intento final.';
  }

  String _nextActionFor(ExerciseStepType weakestType, PracticeObjective objective) {
    switch (weakestType) {
      case ExerciseStepType.fillOptions:
      case ExerciseStepType.typeFirstLetter:
        return 'abre una sesión corta de refuerzo de débiles antes de volver al cierre.';
      case ExerciseStepType.reverseReference:
        return 'mete referencia inversa en la próxima ronda hasta que la referencia salga automática.';
      case ExerciseStepType.thematicBlocks:
        return 'repite bloques temáticos para reforzar contexto, no solo texto literal.';
      case ExerciseStepType.reciteFromMemoryVoice:
      case ExerciseStepType.totalExam:
        return objective == PracticeObjective.duel
            ? 'haz otro duelo corto buscando continuidad y menos pausas.'
            : 'repite el cierre por voz una vez más antes de darlo por dominado.';
      case ExerciseStepType.detectErrors:
      case ExerciseStepType.compareVersions:
        return 'pasa por cards o detección de errores para afinar discriminación textual.';
      default:
        return 'repite primero ese punto débil y luego vuelve al flujo mixto.';
    }
  }
}
