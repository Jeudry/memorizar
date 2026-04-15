enum CooperativeMode {
  solo,
  relay,
  chain,
  rescue,
}

extension CooperativeModeX on CooperativeMode {
  String get label {
    switch (this) {
      case CooperativeMode.solo:
        return 'Solo';
      case CooperativeMode.relay:
        return 'Relevo';
      case CooperativeMode.chain:
        return 'Cadena';
      case CooperativeMode.rescue:
        return 'Rescate';
    }
  }

  String get description {
    switch (this) {
      case CooperativeMode.solo:
        return 'Practicas sin rotación entre jugadores.';
      case CooperativeMode.relay:
        return 'Cada item pasa al siguiente jugador.';
      case CooperativeMode.chain:
        return 'Cada paso rota para que todos continúen la memoria.';
      case CooperativeMode.rescue:
        return 'Si alguien tropieza, otro sigue ese mismo ejercicio.';
    }
  }
}
