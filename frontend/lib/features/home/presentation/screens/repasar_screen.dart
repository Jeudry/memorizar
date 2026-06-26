// Generado del refactor de ui_screens.dart.
// RepasarScreen + helpers.
part of '../ui_screens.dart';

class RepasarScreen extends StatefulWidget {
  const RepasarScreen({super.key});

  @override
  State<RepasarScreen> createState() => _RepasarScreenState();
}

class _RepasarScreenState extends State<RepasarScreen> {
  /// Grupo seleccionado en el slide; null = "Todos".
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final hasGroups = store.groups.isNotEmpty;
    // Si el grupo seleccionado dejó de existir (lo borraron), volvemos a Todos.
    if (_selectedGroupId != null &&
        !store.groups.any((g) => g.id == _selectedGroupId)) {
      _selectedGroupId = null;
    }
    return ReferencePage(
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Mazos'),
          const SizedBox(height: 8),
          // Acción principal de repaso (sin lenguaje de vencimiento) junto al
          // botón para crear grupos.
          Row(
            children: [
              Expanded(
                child: _RecommendedReview(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.flashcards),
                ),
              ),
              const SizedBox(width: 10),
              _NewGroupButton(onTap: () => _createGroupSheet(context, store)),
            ],
          ),
          if (hasGroups) ...[
            const SizedBox(height: 16),
            _GroupsSlide(
              groups: store.groups,
              selectedId: _selectedGroupId,
              countFor: (id) => store.decksInGroup(id).length,
              onSelect: (id) => setState(() => _selectedGroupId = id),
            ),
            if (_selectedGroupId != null) ...[
              const SizedBox(height: 12),
              _GroupBanner(stats: _groupStats(store, _selectedGroupId!)),
            ],
          ],
          const SectionHead('Tus mazos'),
          ..._buildDecks(context, store),
        ],
      ),
    );
  }

  /// Métricas agregadas de un grupo para el banner.
  _GroupStats _groupStats(AppStore store, String groupId) {
    final group = store.groups.firstWhere((g) => g.id == groupId);
    final decks = store.decksInGroup(groupId);
    final cards = decks.fold<int>(0, (s, d) => s + d.cards.length);
    final weak = decks.fold<int>(0, (s, d) => s + d.weakCount);
    // Retención promedio ponderada por número de tarjetas.
    final totalRet =
        decks.fold<int>(0, (s, d) => s + d.retention * d.cards.length);
    final retention = cards == 0 ? 0 : (totalRet / cards).round();
    return _GroupStats(
      icon: group.icon,
      name: group.name,
      deckCount: decks.length,
      cardCount: cards,
      weakCount: weak,
      retention: retention,
    );
  }

  /// Mazos a mostrar según la selección: un grupo concreto (planos) o "Todos"
  /// (agrupados por carpeta, como antes).
  List<Widget> _buildDecks(BuildContext context, AppStore store) {
    if (_selectedGroupId == null) {
      return _buildGroupedDecks(context, store);
    }
    final decks = store.decksInGroup(_selectedGroupId);
    if (decks.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'Este grupo aún no tiene mazos. Abre el menú ⋮ de un mazo para moverlo aquí.',
            style: TextStyle(color: RefColors.muted, fontSize: 12),
          ),
        ),
      ];
    }
    return [for (final deck in decks) _deckTile(context, store, deck)];
  }

  Widget _deckTile(BuildContext context, AppStore store, MemoryDeckData deck) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _DeckRetention(
          deck.icon,
          deck.title,
          '${deck.weakCount} débiles · ${deck.cards.length} tarjetas',
          deck.retention / 100,
          onExport: () => exportDeckToCsv(context, deck),
          onMenu: () => _moveToGroupSheet(context, store, deck),
        ),
      );

  /// Lista los mazos agrupados por carpeta: cada grupo con su encabezado, y
  /// al final los mazos sin grupo. Un mazo pertenece a 0 o 1 grupo.
  List<Widget> _buildGroupedDecks(BuildContext context, AppStore store) {
    final widgets = <Widget>[];
    for (final group in store.groups) {
      final groupDecks = store.decksInGroup(group.id);
      if (groupDecks.isEmpty) continue;
      widgets.add(_GroupHeader('${group.icon} ${group.name}', groupDecks.length));
      widgets.addAll(groupDecks.map((d) => _deckTile(context, store, d)));
    }
    final ungrouped = store.decksInGroup(null);
    if (ungrouped.isNotEmpty) {
      // Solo mostramos el encabezado "Sin grupo" si hay grupos arriba.
      if (store.groups.any((g) => store.decksInGroup(g.id).isNotEmpty)) {
        widgets.add(_GroupHeader('📂 Sin grupo', ungrouped.length));
      }
      widgets.addAll(ungrouped.map((d) => _deckTile(context, store, d)));
    }
    return widgets;
  }

  /// Emojis disponibles para representar una carpeta/grupo.
  static const List<String> _groupEmojiChoices = [
    '📁', '📚', '✝️', '🌍', '💡', '🔥',
    '⭐', '🎯', '🧠', '📝', '🎵', '❤️',
  ];

  /// Pide nombre + ícono de un grupo en un diálogo. Devuelve null si se cancela
  /// o el nombre queda vacío.
  Future<({String name, String icon})?> _promptGroupName(
      BuildContext context) async {
    final controller = TextEditingController();
    String selectedIcon = _groupEmojiChoices.first;
    final result = await showDialog<({String name, String icon})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F0C1B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Nuevo grupo',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nombre del grupo',
                  hintStyle: TextStyle(color: RefColors.muted),
                ),
                onSubmitted: (v) => Navigator.pop(
                    ctx, (name: v, icon: selectedIcon)),
              ),
              const SizedBox(height: 16),
              const Text('Ícono',
                  style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final emoji in _groupEmojiChoices)
                    GestureDetector(
                      onTap: () => setLocalState(() => selectedIcon = emoji),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedIcon == emoji
                              ? RefColors.cyan.withValues(alpha: .18)
                              : HtmlRefColors.glassSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedIcon == emoji
                                ? RefColors.cyan
                                : HtmlRefColors.glassBorder,
                            width: selectedIcon == emoji ? 1.8 : 1.2,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 19)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: RefColors.muted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                  ctx, (name: controller.text, icon: selectedIcon)),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    final trimmed = result?.name.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return (name: trimmed, icon: result!.icon);
  }

  Future<void> _createGroupSheet(BuildContext context, AppStore store) async {
    final res = await _promptGroupName(context);
    if (res != null) await store.createGroup(res.name, icon: res.icon);
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
                final res = await _promptGroupName(context);
                if (res != null) {
                  final id = await store.createGroup(res.name, icon: res.icon);
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
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      color: RefColors.glassSoft,
      child: Row(
        children: [
          GlyphIcon(emoji, size: 22),
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
                const SizedBox(height: 6),
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

/// Métricas agregadas de un grupo, calculadas en RepasarScreen para el banner.
class _GroupStats {
  final String icon;
  final String name;
  final int deckCount;
  final int cardCount;
  final int weakCount;
  final int retention; // 0–100

  const _GroupStats({
    required this.icon,
    required this.name,
    required this.deckCount,
    required this.cardCount,
    required this.weakCount,
    required this.retention,
  });
}

/// Tarjeta de acción principal: sugiere por dónde empezar a repasar, sin
/// lenguaje de vencimiento. Toda la tarjeta es tocable.
class _RecommendedReview extends StatelessWidget {
  final VoidCallback onTap;
  const _RecommendedReview({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        gradient: LinearGradient(
          colors: [
            RefColors.cyan.withValues(alpha: .20),
            RefColors.violet.withValues(alpha: .14),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: RefColors.cyan.withValues(alpha: .30)),
        child: Row(
          children: const [
            GlyphIcon('✨', size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Repaso',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.play_circle_fill_rounded,
                color: RefColors.cyan, size: 28),
          ],
        ),
      ),
    );
  }
}

/// Botón compacto para crear un nuevo grupo, pensado para ir al lado de la
/// tarjeta de Repaso.
class _NewGroupButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewGroupButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        color: HtmlRefColors.glassSoft,
        border: Border.all(color: RefColors.cyan.withValues(alpha: .30)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.create_new_folder_rounded,
                color: RefColors.cyan, size: 18),
            SizedBox(width: 7),
            Text(
              'Grupo',
              style: TextStyle(
                color: RefColors.cyan,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slide horizontal de grupos: "Todos" + cada grupo. Al tocar uno se
/// selecciona y se muestra su banner y sus mazos debajo.
class _GroupsSlide extends StatelessWidget {
  final List<MemoryGroupData> groups;
  final String? selectedId;
  final int Function(String? groupId) countFor;
  final ValueChanged<String?> onSelect;

  const _GroupsSlide({
    required this.groups,
    required this.selectedId,
    required this.countFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _GroupChip(
            emoji: '🗂️',
            label: 'Todos',
            count: countFor(null) +
                groups.fold<int>(0, (s, g) => s + countFor(g.id)),
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final g in groups)
            _GroupChip(
              emoji: g.icon,
              label: g.name,
              count: countFor(g.id),
              selected: selectedId == g.id,
              onTap: () => onSelect(g.id),
            ),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _GroupChip({
    required this.emoji,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? RefColors.cyan.withValues(alpha: .16)
              : HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? RefColors.cyan : HtmlRefColors.glassBorder,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            GlyphIcon(emoji, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? RefColors.cyan : RefColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(999),
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
      ),
    );
  }
}

/// Banner con la info del grupo seleccionado: icono, nombre, progreso de
/// dominio, total de mazos/tarjetas y cuántas están débiles.
class _GroupBanner extends StatelessWidget {
  final _GroupStats stats;
  const _GroupBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .22),
          RefColors.cyan.withValues(alpha: .12),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: RefColors.violet.withValues(alpha: .30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: GlyphIcon(stats.icon, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.deckCount} ${stats.deckCount == 1 ? 'mazo' : 'mazos'} · ${stats.cardCount} tarjetas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: RefColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stats.retention}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: RefColors.lime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

