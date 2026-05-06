enum ExerciseLevel {
  level1,
  level2,
  level3;

  String get label {
    switch (this) {
      case ExerciseLevel.level1:
        return 'Nivel 1';
      case ExerciseLevel.level2:
        return 'Nivel 2';
      case ExerciseLevel.level3:
        return 'Nivel 3';
    }
  }

  double get hiddenFraction {
    switch (this) {
      case ExerciseLevel.level1:
        return 0.5;
      case ExerciseLevel.level2:
        return 0.75;
      case ExerciseLevel.level3:
        return 1.0;
    }
  }

  int allowedMistakes(int totalTokens) {
    switch (this) {
      case ExerciseLevel.level1:
        return (totalTokens * 0.5).ceil();
      case ExerciseLevel.level2:
        return (totalTokens * 0.25).ceil();
      case ExerciseLevel.level3:
        return 1;
    }
  }
}
