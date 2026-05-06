enum MemorizationDifficulty {
  beginner,
  intermediate,
  expert;

  String get label {
    switch (this) {
      case MemorizationDifficulty.beginner:
        return 'Principiante';
      case MemorizationDifficulty.intermediate:
        return 'Intermedio';
      case MemorizationDifficulty.expert:
        return 'Experto';
    }
  }

  String get storageValue => name;

  int get fillOptionCount {
    switch (this) {
      case MemorizationDifficulty.beginner:
        return 4;
      case MemorizationDifficulty.intermediate:
        return 6;
      case MemorizationDifficulty.expert:
        return 9;
    }
  }

  static MemorizationDifficulty fromStorage(String value) {
    return MemorizationDifficulty.values.firstWhere(
      (difficulty) => difficulty.name == value,
      orElse: () => MemorizationDifficulty.beginner,
    );
  }
}
