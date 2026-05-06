import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memorizar/features/practice/data/models/exercise_level.dart';
import 'package:memorizar/features/practice/data/models/exercise_plan_template.dart';
import 'package:memorizar/features/practice/data/models/exercise_step.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';

final exerciseTemplatesProvider = Provider<Map<MemorizationDifficulty, ExercisePlanTemplate>>((ref) {
  return {
    MemorizationDifficulty.beginner: const ExercisePlanTemplate(
      difficulty: MemorizationDifficulty.beginner,
      fixedPrefixCount: 6,
      fixedSuffixCount: 1,
      steps: [
        ExerciseStep(type: ExerciseStepType.listen, instruction: 'Escucha el contenido letra por letra.'),
        ExerciseStep(type: ExerciseStepType.readAlong, instruction: 'Léelo siguiendo la guía visual.'),
        ExerciseStep(
          type: ExerciseStepType.reconstructBlocks,
          instruction: 'Reordena los bloques del contenido para entrar en ritmo.',
        ),
        ExerciseStep(
          type: ExerciseStepType.segmentedRecall,
          instruction: 'Reconstruye el contenido por tramos cortos.',
        ),
        ExerciseStep(type: ExerciseStepType.recordReading, instruction: 'Graba tu voz leyendo el contenido.'),
        ExerciseStep(type: ExerciseStepType.playRecording, instruction: 'Escucha tu grabación sin salir de la sesión.'),
        ExerciseStep(
          type: ExerciseStepType.readHiddenWithVoice,
          level: ExerciseLevel.level1,
          instruction: 'Lee por voz una versión ocultada del contenido.',
          hiddenFractionOverride: 0.5,
          allowedMistakesRatioOverride: 0.3,
        ),
        ExerciseStep(
          type: ExerciseStepType.compareVersions,
          instruction: 'Compara dos versiones y elige la correcta.',
        ),
        ExerciseStep(
          type: ExerciseStepType.understandingQuestion,
          instruction: 'Responde una pregunta de entendimiento sobre el contenido.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level1,
          instruction: 'Completa los espacios usando opciones.',
        ),
        ExerciseStep(
          type: ExerciseStepType.typeFirstLetter,
          level: ExerciseLevel.level1,
          instruction: 'Escribe la primera letra de cada palabra oculta.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level2,
          instruction: 'Completa una versión más exigente.',
        ),
        ExerciseStep(
          type: ExerciseStepType.typeFirstLetter,
          level: ExerciseLevel.level2,
          instruction: 'Reduce pistas y mantén el ritmo.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level3,
          instruction: 'Completa el texto casi sin ayudas.',
        ),
        ExerciseStep(
          type: ExerciseStepType.typeFirstLetter,
          level: ExerciseLevel.level3,
          instruction: 'Acierta con una única tolerancia real.',
        ),
        ExerciseStep(
          type: ExerciseStepType.detectErrors,
          level: ExerciseLevel.level1,
          instruction: 'Encuentra el error escondido en el texto.',
        ),
        ExerciseStep(
          type: ExerciseStepType.detectErrors,
          level: ExerciseLevel.level2,
          instruction: 'Detecta varios errores antes de la recitación final.',
        ),
        ExerciseStep(
          type: ExerciseStepType.reciteFromMemoryVoice,
          instruction: 'Dilo de memoria y deja que la app compare la coincidencia.',
        ),
      ],
    ),
    MemorizationDifficulty.intermediate: const ExercisePlanTemplate(
      difficulty: MemorizationDifficulty.intermediate,
      fixedPrefixCount: 4,
      fixedSuffixCount: 1,
      steps: [
        ExerciseStep(type: ExerciseStepType.listen, instruction: 'Escucha el texto una vez.'),
        ExerciseStep(
          type: ExerciseStepType.reconstructBlocks,
          instruction: 'Rearma bloques clave antes de ir al examen.',
        ),
        ExerciseStep(type: ExerciseStepType.recordReading, instruction: 'Graba una lectura breve.'),
        ExerciseStep(
          type: ExerciseStepType.readHiddenWithVoice,
          level: ExerciseLevel.level1,
          instruction: 'Lee la versión ocultada usando tu voz.',
          hiddenFractionOverride: 0.5,
          allowedMistakesRatioOverride: 0.3,
        ),
        ExerciseStep(
          type: ExerciseStepType.compareVersions,
          instruction: 'Elige la versión fiel al contenido.',
        ),
        ExerciseStep(
          type: ExerciseStepType.understandingQuestion,
          instruction: 'Responde una pregunta de comprensión antes del cierre.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level1,
          instruction: 'Completa con menos soporte visual.',
        ),
        ExerciseStep(
          type: ExerciseStepType.cutIn,
          instruction: 'Continúa el contenido justo después del corte.',
        ),
        ExerciseStep(
          type: ExerciseStepType.typeFirstLetter,
          level: ExerciseLevel.level2,
          instruction: 'Pasa rápido a la primera letra.',
        ),
        ExerciseStep(
          type: ExerciseStepType.randomStart,
          instruction: 'Empieza desde un punto aleatorio del contenido.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level3,
          instruction: 'Resuelve la versión más dura.',
        ),
        ExerciseStep(
          type: ExerciseStepType.detectErrors,
          level: ExerciseLevel.level1,
          instruction: 'Encuentra el error textual antes del cierre.',
        ),
        ExerciseStep(
          type: ExerciseStepType.reciteFromMemoryVoice,
          instruction: 'Haz la recitación final por voz.',
        ),
      ],
    ),
    MemorizationDifficulty.expert: const ExercisePlanTemplate(
      difficulty: MemorizationDifficulty.expert,
      fixedPrefixCount: 1,
      fixedSuffixCount: 1,
      steps: [
        ExerciseStep(
          type: ExerciseStepType.reconstructBlocks,
          instruction: 'Reordena los bloques sin calentamiento extra.',
        ),
        ExerciseStep(
          type: ExerciseStepType.compareVersions,
          instruction: 'Distingue la versión correcta sin pistas extra.',
        ),
        ExerciseStep(
          type: ExerciseStepType.understandingQuestion,
          instruction: 'Confirma que entendiste la idea central.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level1,
          instruction: 'Arranca directo con completado.',
        ),
        ExerciseStep(
          type: ExerciseStepType.cutIn,
          instruction: 'Recupéralo desde un corte inesperado.',
        ),
        ExerciseStep(
          type: ExerciseStepType.typeFirstLetter,
          level: ExerciseLevel.level2,
          instruction: 'Primera letra sin rodeos.',
        ),
        ExerciseStep(
          type: ExerciseStepType.randomStart,
          instruction: 'Arranca desde un punto aleatorio sin contexto previo.',
        ),
        ExerciseStep(
          type: ExerciseStepType.fillOptions,
          level: ExerciseLevel.level3,
          instruction: 'Completa sin ayudas visibles.',
        ),
        ExerciseStep(
          type: ExerciseStepType.pressureRecall,
          instruction: 'Recita bajo presión y con poco margen de pausa.',
        ),
        ExerciseStep(
          type: ExerciseStepType.detectErrors,
          level: ExerciseLevel.level2,
          instruction: 'Ubica los errores finales antes de recitar.',
        ),
        ExerciseStep(
          type: ExerciseStepType.totalExam,
          instruction: 'Examen total casi sin ayudas.',
        ),
        ExerciseStep(
          type: ExerciseStepType.reciteFromMemoryVoice,
          instruction: 'Confirma por voz lo que ya dominaste.',
        ),
      ],
    ),
  };
});
