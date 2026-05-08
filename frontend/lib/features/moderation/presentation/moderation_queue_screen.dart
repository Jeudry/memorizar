import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';
import '../data/report_models.dart';

/// Cola interna para revisar reportes pendientes. En Fase 1 vive solo en
/// memoria del store; en Fase 3 esta misma pantalla apuntará al backend con
/// permisos de moderador.
class ModerationQueueScreen extends StatelessWidget {
  const ModerationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pending = store.deckReports
        .where((r) => r.status == ReportStatus.pending)
        .toList();
    final history = store.deckReports
        .where((r) => r.status != ReportStatus.pending)
        .toList();
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Moderación'),
          if (pending.isEmpty && history.isEmpty)
            Glass(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 28,
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.shield_moon_rounded,
                    color: RefColors.lime,
                    size: 36,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sin reportes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cuando alguien reporte un mazo público aparecerá aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              const SectionHead('Pendientes'),
              for (final r in pending)
                _ReportRow(report: r, store: store, isPending: true),
            ],
            if (history.isNotEmpty) ...[
              const SectionHead('Resueltos'),
              for (final r in history)
                _ReportRow(report: r, store: store, isPending: false),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final DeckReport report;
  final AppStore store;
  final bool isPending;
  const _ReportRow({
    required this.report,
    required this.store,
    required this.isPending,
  });

  Color _statusColor() {
    switch (report.status) {
      case ReportStatus.pending:
        return RefColors.sun;
      case ReportStatus.resolvedKept:
        return RefColors.lime;
      case ReportStatus.resolvedHidden:
        return RefColors.cyan;
      case ReportStatus.resolvedRemoved:
        return RefColors.urgent;
    }
  }

  String _statusLabel() {
    switch (report.status) {
      case ReportStatus.pending:
        return 'Pendiente';
      case ReportStatus.resolvedKept:
        return 'Mantenido';
      case ReportStatus.resolvedHidden:
        return 'Oculto';
      case ReportStatus.resolvedRemoved:
        return 'Eliminado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: HtmlRefColors.glassSoft,
      border: Border.all(color: HtmlRefColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.deckTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _statusColor().withValues(alpha: .55),
                  ),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Razón: ${report.reason.label}',
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (report.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              report.note,
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    'Mantener',
                    onTap: () => store.resolveDeckReport(
                      report.id,
                      ReportStatus.resolvedKept,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GhostButton(
                    'Ocultar',
                    onTap: () => store.resolveDeckReport(
                      report.id,
                      ReportStatus.resolvedHidden,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GhostButton(
                    'Eliminar',
                    onTap: () => store.resolveDeckReport(
                      report.id,
                      ReportStatus.resolvedRemoved,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
