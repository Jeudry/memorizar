import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';
import '../data/report_models.dart';

/// Cola de moderación. Con sesión iniciada lee y resuelve los reportes
/// persistidos en el backend; sin sesión cae a la copia local del store.
/// La autorización por rol de moderador queda pendiente.
class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  List<DeckReport>? _remoteReports;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading || !mounted) return;
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() => _loading = true);
    try {
      final raw = await store.api.listDeckReports();
      if (!mounted) return;
      setState(() =>
          _remoteReports = raw.map(DeckReport.fromApi).toList());
    } catch (e) {
      debugPrint('Cola de moderación: fallback local ($e)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(
    AppStore store,
    DeckReport report,
    ReportStatus status,
  ) async {
    if (_remoteReports != null) {
      try {
        await store.api.resolveDeckReport(
          reportId: report.id,
          resolution: status.resolutionKey,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo resolver el reporte.')),
        );
        return;
      }
    }
    store.resolveDeckReport(report.id, status);
    if (!mounted) return;
    setState(() {
      _remoteReports = _remoteReports
          ?.map((r) => r.id == report.id ? r.copyWith(status: status) : r)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final reports = _remoteReports ?? store.deckReports;
    final pending =
        reports.where((r) => r.status == ReportStatus.pending).toList();
    final history =
        reports.where((r) => r.status != ReportStatus.pending).toList();
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Moderación'),
          if (_loading && _remoteReports == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: RefColors.cyan),
              ),
            )
          else if (pending.isEmpty && history.isEmpty)
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
                _ReportRow(
                  report: r,
                  isPending: true,
                  onResolve: (status) => _resolve(store, r, status),
                ),
            ],
            if (history.isNotEmpty) ...[
              const SectionHead('Resueltos'),
              for (final r in history)
                _ReportRow(
                  report: r,
                  isPending: false,
                  onResolve: (status) => _resolve(store, r, status),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final DeckReport report;
  final bool isPending;
  final ValueChanged<ReportStatus> onResolve;
  const _ReportRow({
    required this.report,
    required this.isPending,
    required this.onResolve,
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
                    onTap: () => onResolve(ReportStatus.resolvedKept),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GhostButton(
                    'Ocultar',
                    onTap: () => onResolve(ReportStatus.resolvedHidden),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GhostButton(
                    'Eliminar',
                    onTap: () => onResolve(ReportStatus.resolvedRemoved),
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
