import 'package:memorizar/features/practice/data/models/exercise_level.dart';

enum ExerciseStepType {
  listen,
  readAlong,
  reconstructBlocks,
  segmentedRecall,
  thematicBlocks,
  recordReading,
  playRecording,
  readHiddenWithVoice,
  reverseReference,
  compareVersions,
  cutIn,
  randomStart,
  fillOptions,
  typeFirstLetter,
  understandingQuestion,
  detectErrors,
  reciteFromMemoryVoice,
  pressureRecall,
  totalExam,
  coachReview;

  String get storageValue {
    switch (this) {
      case ExerciseStepType.listen:
        return 'listen';
      case ExerciseStepType.readAlong:
        return 'read_along';
      case ExerciseStepType.reconstructBlocks:
        return 'reconstruct_blocks';
      case ExerciseStepType.segmentedRecall:
        return 'segmented_recall';
      case ExerciseStepType.thematicBlocks:
        return 'thematic_blocks';
      case ExerciseStepType.recordReading:
        return 'record_reading';
      case ExerciseStepType.playRecording:
        return 'play_recording';
      case ExerciseStepType.readHiddenWithVoice:
        return 'read_hidden_with_voice';
      case ExerciseStepType.reverseReference:
        return 'reverse_reference';
      case ExerciseStepType.compareVersions:
        return 'compare_versions';
      case ExerciseStepType.cutIn:
        return 'cut_in';
      case ExerciseStepType.randomStart:
        return 'random_start';
      case ExerciseStepType.fillOptions:
        return 'fill_options';
      case ExerciseStepType.typeFirstLetter:
        return 'type_first_letter';
      case ExerciseStepType.understandingQuestion:
        return 'understanding_question';
      case ExerciseStepType.detectErrors:
        return 'detect_errors';
      case ExerciseStepType.reciteFromMemoryVoice:
        return 'recite_from_memory_voice';
      case ExerciseStepType.pressureRecall:
        return 'pressure_recall';
      case ExerciseStepType.totalExam:
        return 'total_exam';
      case ExerciseStepType.coachReview:
        return 'coach_review';
    }
  }

  String get label {
    switch (this) {
      case ExerciseStepType.listen:
        return 'Escuchar';
      case ExerciseStepType.readAlong:
        return 'Leer';
      case ExerciseStepType.reconstructBlocks:
        return 'Reconstruir bloques';
      case ExerciseStepType.segmentedRecall:
        return 'Por tramos';
      case ExerciseStepType.thematicBlocks:
        return 'Bloques temáticos';
      case ExerciseStepType.recordReading:
        return 'Grabar tu voz';
      case ExerciseStepType.playRecording:
        return 'Escuchar grabación';
      case ExerciseStepType.readHiddenWithVoice:
        return 'Leer ocultado por voz';
      case ExerciseStepType.reverseReference:
        return 'Referencia inversa';
      case ExerciseStepType.compareVersions:
        return 'Comparar versiones';
      case ExerciseStepType.cutIn:
        return 'Modo corte';
      case ExerciseStepType.randomStart:
        return 'Arranque aleatorio';
      case ExerciseStepType.fillOptions:
        return 'Completar';
      case ExerciseStepType.typeFirstLetter:
        return 'Primera letra';
      case ExerciseStepType.understandingQuestion:
        return 'Entendimiento IA';
      case ExerciseStepType.detectErrors:
        return 'Detectar errores';
      case ExerciseStepType.reciteFromMemoryVoice:
        return 'Decirlo de memoria';
      case ExerciseStepType.pressureRecall:
        return 'Modo presión';
      case ExerciseStepType.totalExam:
        return 'Examen total';
      case ExerciseStepType.coachReview:
        return 'Coach IA';
    }
  }
}

class ExerciseStep {
  const ExerciseStep({
    required this.type,
    this.level,
    required this.instruction,
    this.hiddenFractionOverride,
    this.allowedMistakesRatioOverride,
  });

  final ExerciseStepType type;
  final ExerciseLevel? level;
  final String instruction;
  final double? hiddenFractionOverride;
  final double? allowedMistakesRatioOverride;

  bool get isExamStep => level != null;
}
