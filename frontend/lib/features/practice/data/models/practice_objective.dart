enum PracticeObjective {
  quick,
  deep,
  duel,
  totalExam,
  master;

  String get storageValue => name;

  String get label {
    switch (this) {
      case PracticeObjective.quick:
        return 'Memorizar rápido';
      case PracticeObjective.deep:
        return 'Más profundo';
      case PracticeObjective.duel:
        return 'Modo duelo';
      case PracticeObjective.totalExam:
        return 'Examen total';
      case PracticeObjective.master:
        return 'Modo maestro';
    }
  }

  String get description {
    switch (this) {
      case PracticeObjective.quick:
        return 'Menos ejercicios, más ritmo.';
      case PracticeObjective.deep:
        return 'Más variedad, contexto y voz.';
      case PracticeObjective.duel:
        return 'Compite contra tu mejor marca.';
      case PracticeObjective.totalExam:
        return 'Casi sin ayudas, directo a demostrar dominio.';
      case PracticeObjective.master:
        return 'La app elige lo más duro y corta ayudas si vas demasiado bien.';
    }
  }
}
