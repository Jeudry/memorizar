import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';
import '../data/report_models.dart';

/// Bottom-sheet para reportar un mazo público. Muestra las razones, deja al
/// usuario escribir una nota opcional, y al confirmar añade un [DeckReport]
/// a la cola del store.
Future<void> showReportDeckSheet(
  BuildContext context, {
  required String deckId,
  required String deckTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ReportDeckSheet(deckId: deckId, deckTitle: deckTitle),
  );
}

class _ReportDeckSheet extends StatefulWidget {
  final String deckId;
  final String deckTitle;
  const _ReportDeckSheet({required this.deckId, required this.deckTitle});

  @override
  State<_ReportDeckSheet> createState() => _ReportDeckSheetState();
}

class _ReportDeckSheetState extends State<_ReportDeckSheet> {
  ReportReason _reason = ReportReason.copyright;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = AppScope.of(context);
    store.fileDeckReport(
      deckId: widget.deckId,
      deckTitle: widget.deckTitle,
      reason: _reason,
      note: _noteController.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporte enviado · revisaremos en hasta 72h'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + viewInsets.bottom),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: RefColors.urgent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reportar "${widget.deckTitle}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecciona la razón. Tu reporte va a moderación junto con el mazo, no a su creador.',
              style: TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final r in ReportReason.values)
                      _ReasonRow(
                        reason: r,
                        selected: _reason == r,
                        onTap: () => setState(() => _reason = r),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 280,
              style: const TextStyle(color: RefColors.ink, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nota opcional (qué viste, dónde…)',
                hintStyle: const TextStyle(
                  color: RefColors.dim,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: HtmlRefColors.glassSoft,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: HtmlRefColors.glassBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: HtmlRefColors.glassBorder,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    'Cancelar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Cta('Enviar reporte', onTap: _submit)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? RefColors.pink.withValues(alpha: .18)
              : HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? RefColors.pink.withValues(alpha: .6)
                : HtmlRefColors.glassBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: selected ? RefColors.pink : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.6,
                  color: selected ? RefColors.pink : RefColors.muted,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason.description,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
