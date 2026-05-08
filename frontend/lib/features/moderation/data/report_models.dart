/// Razones por las que un usuario puede reportar un mazo público.
/// El valor `serverKey` es el que se envía al backend cuando exista (Fase 3+).
enum ReportReason {
  copyright(
    serverKey: 'copyright',
    label: 'Copyright',
    description:
        'Reproduce contenido bajo derechos de autor sin permiso (ej. una versión moderna de la Biblia).',
  ),
  hate(
    serverKey: 'hate',
    label: 'Discurso de odio',
    description:
        'Acoso, amenazas, ataques personales o discriminación.',
  ),
  sexual(
    serverKey: 'sexual',
    label: 'Contenido sexual',
    description: 'Sexual explícito o gráfico.',
  ),
  minorRisk(
    serverKey: 'minor_risk',
    label: 'Daño a menores',
    description: 'Pone en riesgo a niños o adolescentes.',
  ),
  spam(
    serverKey: 'spam',
    label: 'Spam',
    description: 'Spam, links maliciosos o promociones engañosas.',
  ),
  impersonation(
    serverKey: 'impersonation',
    label: 'Suplantación',
    description: 'Suplanta identidad de líderes, marcas o personas reales.',
  ),
  inaccurate(
    serverKey: 'inaccurate',
    label: 'Texto incorrecto',
    description:
        'Errores de transcripción importantes o referencias erradas.',
  ),
  other(
    serverKey: 'other',
    label: 'Otro',
    description: 'Otra razón — descríbela en la nota.',
  );

  final String serverKey;
  final String label;
  final String description;
  const ReportReason({
    required this.serverKey,
    required this.label,
    required this.description,
  });
}

/// Estado de un reporte tal como lo ve la cola de moderación.
enum ReportStatus { pending, resolvedKept, resolvedHidden, resolvedRemoved }

class DeckReport {
  final String id;
  final String deckId;
  final String deckTitle;
  final String reporterId;
  final ReportReason reason;
  final String note;
  final DateTime createdAt;
  final ReportStatus status;

  const DeckReport({
    required this.id,
    required this.deckId,
    required this.deckTitle,
    required this.reporterId,
    required this.reason,
    required this.note,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  DeckReport copyWith({ReportStatus? status}) => DeckReport(
        id: id,
        deckId: deckId,
        deckTitle: deckTitle,
        reporterId: reporterId,
        reason: reason,
        note: note,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
