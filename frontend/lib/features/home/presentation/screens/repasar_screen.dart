// Generado del refactor de ui_screens.dart.
// RepasarScreen + helpers.
part of '../ui_screens.dart';

class RepasarScreen extends StatelessWidget {
  const RepasarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final weakCount = store.dueTodayCount;
    return ReferencePage(
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Repasar'),
          const _PageHead(
            'Memoria activa',
            'Rescata lo que ya dominaste antes de que se pierda',
          ),
          Glass(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              colors: [
                RefColors.urgent.withValues(alpha: .22),
                RefColors.sun.withValues(alpha: .12),
              ],
            ),
            border: Border.all(color: RefColors.urgent.withValues(alpha: .35)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RefChip(
                  '⚠ EN RIESGO',
                  dense: true,
                  color: Color(0x33FF5A8A),
                  textColor: Color(0xFFFFB8CC),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: RefColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              RefColors.primary.createShader(bounds),
                          child: Text(
                            '$weakCount tarjetas',
                            style: TextStyle(
                              color: RefColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' tienen repaso vencido hoy'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Un repaso de 5 minutos ahora las salva de perderse.',
                  style: TextStyle(color: RefColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Cta(
                  '▶ Rescatar ahora · 5 min',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.flashcards),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: const [
                GlyphIcon('✨', size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repaso recomendado',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Empieza por tarjetas débiles · luego mazos',
                        style: TextStyle(fontSize: 11, color: RefColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '›',
                  style: TextStyle(fontSize: 26, color: RefColors.muted),
                ),
              ],
            ),
          ),
          SectionHead(
            'Tus mazos',
            action: '＋ Grupo',
            onAction: () => _createGroupSheet(context, store),
          ),
          ..._buildGroupedDecks(context, store),
        ],
      ),
    );
  }

  /// Lista los mazos agrupados por carpeta: cada grupo con su encabezado, y
  /// al final los mazos sin grupo. Un mazo pertenece a 0 o 1 grupo.
  List<Widget> _buildGroupedDecks(BuildContext context, AppStore store) {
    Widget deckTile(MemoryDeckData deck) => _DeckRetention(
          deck.icon,
          deck.title,
          '${deck.weakCount} débiles · ${deck.cards.length} tarjetas',
          deck.retention / 100,
          onExport: () => exportDeckToCsv(context, deck),
          onMenu: () => _moveToGroupSheet(context, store, deck),
        );

    final widgets = <Widget>[];
    for (final group in store.groups) {
      final groupDecks = store.decksInGroup(group.id);
      if (groupDecks.isEmpty) continue;
      widgets.add(_GroupHeader('${group.icon} ${group.name}', groupDecks.length));
      widgets.addAll(groupDecks.map(deckTile));
    }
    final ungrouped = store.decksInGroup(null);
    if (ungrouped.isNotEmpty) {
      // Solo mostramos el encabezado "Sin grupo" si hay grupos arriba.
      if (store.groups.any((g) => store.decksInGroup(g.id).isNotEmpty)) {
        widgets.add(_GroupHeader('📂 Sin grupo', ungrouped.length));
      }
      widgets.addAll(ungrouped.map(deckTile));
    }
    return widgets;
  }

  /// Pide un nombre de grupo en un diálogo. Devuelve el nombre o null.
  Future<String?> _promptGroupName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0C1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Nuevo grupo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre del grupo',
            hintStyle: TextStyle(color: RefColors.muted),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: RefColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _createGroupSheet(BuildContext context, AppStore store) async {
    final name = await _promptGroupName(context);
    if (name != null) await store.createGroup(name);
  }

  /// Hoja para mover un mazo a un grupo (o sin grupo / crear uno nuevo).
  Future<void> _moveToGroupSheet(
      BuildContext context, AppStore store, MemoryDeckData deck) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F0C1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Mover "${deck.title}" a…',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off_rounded, color: RefColors.muted),
              title: const Text('Sin grupo', style: TextStyle(color: Colors.white)),
              trailing: deck.groupId == null
                  ? const Icon(Icons.check_rounded, color: RefColors.lime)
                  : null,
              onTap: () {
                store.assignDeckToGroup(deck.id, null);
                Navigator.pop(ctx);
              },
            ),
            for (final g in store.groups)
              ListTile(
                leading: Text(g.icon, style: const TextStyle(fontSize: 18)),
                title: Text(g.name, style: const TextStyle(color: Colors.white)),
                trailing: deck.groupId == g.id
                    ? const Icon(Icons.check_rounded, color: RefColors.lime)
                    : null,
                onTap: () {
                  store.assignDeckToGroup(deck.id, g.id);
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: RefColors.cyan),
              title: const Text('Nuevo grupo…', style: TextStyle(color: RefColors.cyan)),
              onTap: () async {
                Navigator.pop(ctx);
                final name = await _promptGroupName(context);
                if (name != null) {
                  final id = await store.createGroup(name);
                  await store.assignDeckToGroup(deck.id, id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;

  const _GroupHeader(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: RefColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: HtmlRefColors.glassBorder),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: RefColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckRetention extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final double value;
  final VoidCallback? onExport;
  final VoidCallback? onMenu;

  const _DeckRetention(this.emoji, this.title, this.subtitle, this.value,
      {this.onExport, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(12),
      color: RefColors.glassSoft,
      child: Row(
        children: [
          GlyphIcon(emoji, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: RefColors.muted),
                ),
                const SizedBox(height: 8),
                RefProgress(value),
              ],
            ),
          ),
          if (onExport != null)
            GestureDetector(
              onTap: onExport,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RefColors.glassStrong,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RefColors.border),
                ),
                child: const Icon(Icons.ios_share_rounded,
                    size: 17, color: RefColors.cyan),
              ),
            ),
          if (onMenu != null)
            GestureDetector(
              onTap: onMenu,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RefColors.glassStrong,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RefColors.border),
                ),
                child: const Icon(Icons.more_vert_rounded,
                    size: 17, color: RefColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

