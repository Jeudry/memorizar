// Generado del refactor de ui_screens.dart.
// ComunidadScreen + helpers.
part of '../ui_screens.dart';

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  static const int _exploreTab = 0;
  static const int _myDecksTab = 1;

  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>>? _results;
  bool _searching = false;

  int _tabIndex = _exploreTab;
  List<Map<String, dynamic>>? _myDecks;
  bool _loadingMine = false;
  String? _mineError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    if (index == _myDecksTab && _myDecks == null) {
      _loadMyDecks();
    }
  }

  Future<void> _loadMyDecks() async {
    if (_loadingMine) return;
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      setState(() {
        _mineError = 'Inicia sesión para ver tus decks publicados.';
        _myDecks = const [];
      });
      return;
    }
    setState(() {
      _loadingMine = true;
      _mineError = null;
    });
    try {
      final decks = await store.api.listMyCommunityDecks();
      if (!mounted) return;
      setState(() => _myDecks = decks);
    } catch (e) {
      if (!mounted) return;
      setState(() => _mineError = 'No se pudieron cargar tus decks publicados.');
      debugPrint('Error cargando mis decks comunitarios: $e');
    } finally {
      if (mounted) setState(() => _loadingMine = false);
    }
  }

  /// Selector de mazos locales para publicar a la comunidad. Al elegir uno
  /// se abre el sheet de visibilidad/consentimiento que hace la publicación.
  void _startPublishFlow() {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para publicar en la comunidad.')),
      );
      return;
    }
    final candidates = store.decks.where((deck) => deck.cards.isNotEmpty).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea un mazo con tarjetas antes de publicarlo.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HtmlRefColors.glassBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Qué mazo quieres publicar?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final deck in candidates)
                    ListTile(
                      leading: GlyphIcon(deck.icon, size: 22),
                      title: Text(
                        deck.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${deck.cards.length} tarjetas',
                        style: const TextStyle(color: RefColors.muted, fontSize: 11),
                      ),
                      onTap: () async {
                        Navigator.of(sheetCtx).pop();
                        await showVisibilityConsentSheet(
                          context,
                          deckId: deck.id,
                          deckTitle: deck.title,
                          current: deck.visibility,
                        );
                        _loadMyDecks();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(v));
  }

  Future<void> _runSearch(String q) async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para buscar en la comunidad.')),
      );
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await store.api.searchCommunityDecks(q);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _import(Map<String, dynamic> share) async {
    final store = AppScope.of(context);
    try {
      final raw = (share['payloadJson'] as String?) ?? '';
      if (raw.isEmpty) throw Exception('payload vacío');
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final cards = (payload['cards'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((c) => MemoryCardData(
                id: 'comm-${DateTime.now().microsecondsSinceEpoch}-${c['id']}',
                front: (c['front'] as String?) ?? '',
                back: (c['back'] as String?) ?? '',
                source: (c['source'] as String?) ?? 'Comunidad',
                icon: (c['icon'] as String?) ?? '🌍',
              ))
          .toList();
      store.createDeckFromCards(
        title: '${payload['title'] ?? share['title']} (comunidad)',
        icon: (payload['icon'] as String?) ?? '🌍',
        cards: cards,
      );
      // Registrar la importación para las stats comunitarias del autor.
      final shareId = (share['id'] as String?) ?? '';
      if (shareId.isNotEmpty) {
        unawaited(store.api.registerCommunityImport(shareId).catchError((e) {
          debugPrint('No se pudo registrar import comunitario: $e');
        }));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mazo importado a tu colección')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar: $e')),
      );
    }
  }

  void _showReportDialog(BuildContext context, String deckTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RefColors.glassStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: RefColors.border),
          ),
          title: Row(
            children: const [
              Icon(Icons.copyright_rounded, color: RefColors.urgent),
              SizedBox(width: 8),
              Text(
                'Reportar Copyright',
                style: TextStyle(color: RefColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            '¿Deseas reportar el mazo "$deckTitle" por infracción de propiedad intelectual o derechos de autor (DMCA)?',
            style: const TextStyle(color: RefColors.ink, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: RefColors.muted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RefColors.urgent.withValues(alpha: .15),
                foregroundColor: RefColors.urgent,
                elevation: 0,
                side: const BorderSide(color: RefColors.urgent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: RefColors.glassStrong,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: RefColors.lime),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: const Text(
                      'Reporte registrado exitosamente. Revisaremos el contenido en un plazo máximo de 24 horas.',
                      style: TextStyle(color: RefColors.lime, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              child: const Text('Reportar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabSwitcher() {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ComunidadTab(
              label: 'Explorar',
              icon: Icons.public_rounded,
              selected: _tabIndex == _exploreTab,
              onTap: () => _switchTab(_exploreTab),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ComunidadTab(
              label: 'Mis decks',
              icon: Icons.collections_bookmark_rounded,
              selected: _tabIndex == _myDecksTab,
              onTap: () => _switchTab(_myDecksTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDecksTab() {
    if (_loadingMine) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: RefColors.cyan)),
      );
    }
    if (_mineError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              _mineError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: RefColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Cta('Reintentar', onTap: _loadMyDecks),
          ],
        ),
      );
    }
    final mine = _myDecks ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Cta('+ Publicar un mazo a la comunidad', onTap: _startPublishFlow),
        const SizedBox(height: 14),
        if (mine.isEmpty)
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: Column(
              children: const [
                Icon(Icons.cloud_upload_outlined, color: RefColors.cyan, size: 42),
                SizedBox(height: 12),
                Text(
                  'Aún no publicaste ningún mazo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'Comparte tus mazos con la comunidad y mira cuántas personas los importan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: RefColors.muted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          )
        else ...[
          Text(
            '${mine.length} ${mine.length == 1 ? 'MAZO PUBLICADO' : 'MAZOS PUBLICADOS'}',
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          for (final deck in mine) _MyCommunityDeckCard(share: deck),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final decks = store.decks;
    return ReferencePage(
      active: AppRoutes.comunidad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Comunidad'),
          const _PageHead(
            'Descubre mazos',
            'Creados por personas que aprenden como tú',
          ),
          _buildTabSwitcher(),
          const SizedBox(height: 12),
          if (_tabIndex == _myDecksTab) ...[
            _buildMyDecksTab(),
          ] else ...[
          Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: RefColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RefColors.ink,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Buscar por tema, idioma, asignatura…',
                      hintStyle: TextStyle(color: RefColors.dim, fontSize: 12),
                    ),
                  ),
                ),
                if (_searching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _results = null);
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: RefColors.muted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          if (_results != null) ...[
            const SizedBox(height: 12),
            if (_results!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Sin resultados.',
                  style: TextStyle(color: RefColors.muted, fontSize: 12),
                ),
              )
            else
              for (final r in _results!)
                _CommunityHit(
                  share: r,
                  onImport: () => _import(r),
                  onReport: () => _showReportDialog(context, r['title'] as String? ?? 'Sin título'),
                ),
          ],
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.45,
            children: const [
              _CategoryTile('🧠', 'Medicina', '184'),
              _CategoryTile('🌍', 'Idiomas', '412'),
              _CategoryTile('🧪', 'Ciencias', '256'),
              _CategoryTile('📜', 'Historia', '130'),
              _CategoryTile('✝️', 'Biblia', '89'),
              _CategoryTile('🎨', 'Arte', '76'),
              _CategoryTile('💻', 'Tech', '208'),
              _CategoryTile('⋯', 'Más', 'Todos'),
            ],
          ),
          const SizedBox(height: 6),
          const SectionHead('Destacado esta semana', action: 'Ver todo'),
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final deck in decks.take(3))
                  _FeaturedDeck(
                    deck.icon,
                    deck.title,
                    '${deck.cards.length} tarjetas · ${deck.retention}% retención',
                    '★ ${(4 + deck.retention / 100).toStringAsFixed(1)}',
                    LinearGradient(
                      colors: [
                        RefColors.pink.withValues(alpha: .22),
                        RefColors.violet.withValues(alpha: .22),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      store.setActiveDeck(deck.id);
                      Navigator.pushNamed(context, AppRoutes.iniciar);
                    },
                  ),
              ],
            ),
          ),
          const SectionHead('Populares', action: 'Filtrar'),
          _DeckGrid(decks: decks),
          const SectionHead('Creadores a seguir', action: 'Ver todos'),
          for (final deck in decks.take(2))
            _Creator(
              deck.title.characters.first.toUpperCase(),
              '${deck.title} · local',
              '${deck.cards.length} tarjetas disponibles',
              '${deck.retention}%',
              cyan: deck.isBible,
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de pestaña del switcher Explorar / Mis decks.
class _ComunidadTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ComunidadTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? RefColors.primary : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : RefColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : RefColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de un deck publicado por mí, con sus stats comunitarias.
class _MyCommunityDeckCard extends StatelessWidget {
  final Map<String, dynamic> share;

  const _MyCommunityDeckCard({required this.share});

  int _cardCount() {
    try {
      final raw = (share['payloadJson'] as String?) ?? '';
      if (raw.isEmpty) return 0;
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      return (payload['cards'] as List? ?? const []).length;
    } catch (_) {
      return 0;
    }
  }

  String _publishedAgo() {
    final raw = (share['createdAt'] as String?) ?? '';
    final created = DateTime.tryParse(raw);
    if (created == null) return '';
    final days = DateTime.now().toUtc().difference(created.toUtc()).inDays;
    if (days <= 0) return 'publicado hoy';
    if (days == 1) return 'publicado hace 1 día';
    return 'publicado hace $days días';
  }

  @override
  Widget build(BuildContext context) {
    final title = (share['title'] as String?) ?? 'Sin título';
    final summary = (share['summary'] as String?) ?? '';
    final importCount = (share['importCount'] as int?) ?? 0;
    final cardCount = _cardCount();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, color: RefColors.cyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                RefChip(
                  '🌍 PÚBLICO',
                  dense: true,
                  color: const Color(0x2200D4FF),
                  textColor: RefColors.cyan,
                ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                summary,
                style: const TextStyle(color: RefColors.muted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _MyDeckStat(
                  icon: Icons.download_rounded,
                  value: '$importCount',
                  label: importCount == 1 ? 'importación' : 'importaciones',
                ),
                const SizedBox(width: 14),
                if (cardCount > 0)
                  _MyDeckStat(
                    icon: Icons.style_rounded,
                    value: '$cardCount',
                    label: 'tarjetas',
                  ),
                const Spacer(),
                Text(
                  _publishedAgo(),
                  style: const TextStyle(color: RefColors.dim, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyDeckStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MyDeckStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: RefColors.sun),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: RefColors.sun,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: RefColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _CommunityHit extends StatelessWidget {
  final Map<String, dynamic> share;
  final VoidCallback onImport;
  final VoidCallback onReport;
  
  const _CommunityHit({
    required this.share,
    required this.onImport,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final title = (share['title'] as String?) ?? 'Sin título';
    final summary = (share['summary'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, color: RefColors.cyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onReport,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: RefColors.urgent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RefColors.urgent.withValues(alpha: .4)),
              ),
              child: const Icon(
                Icons.copyright_rounded,
                color: RefColors.urgent,
                size: 16,
              ),
            ),
          ),
          GestureDetector(
            onTap: onImport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: RefColors.lime.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              ),
              child: const Text(
                'Importar',
                style: TextStyle(
                  color: RefColors.lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Creator extends StatelessWidget {
  final String initial;
  final String title;
  final String subtitle;
  final String stats;
  final bool cyan;

  const _Creator(
    this.initial,
    this.title,
    this.subtitle,
    this.stats, {
    this.cyan = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Fav(
              initial,
              gradient: cyan ? RefColors.cool : RefColors.primary,
              size: 42,
              online: cyan,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: RefColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              stats,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: RefColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckThumb extends StatelessWidget {
  final String glyph;

  const _DeckThumb(this.glyph);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: HtmlRefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      alignment: Alignment.center,
      child: GlyphIcon(glyph, size: 24),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String count;

  const _CategoryTile(this.emoji, this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      color: const Color(0x10FFFFFF),
      border: Border.all(color: const Color(0x24FFFFFF)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlyphIcon(emoji, size: 21),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: const TextStyle(fontSize: 8.5, color: RefColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDeck extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String rating;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _FeaturedDeck(
    this.emoji,
    this.title,
    this.subtitle,
    this.rating,
    this.gradient, {
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 10),
        child: Glass(
          padding: const EdgeInsets.all(16),
          gradient: gradient,
          border: Border.all(color: HtmlRefColors.glassBorder),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -12,
                child: GlyphIcon(
                  emoji,
                  size: 80,
                  color: Colors.white.withValues(alpha: .2),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: RefColors.muted,
                    ),
                  ),
                  const Spacer(),
                  RefChip(
                    rating,
                    dense: true,
                    color: const Color(0x22FFB400),
                    textColor: RefColors.sun,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckGrid extends StatelessWidget {
  final List<MemoryDeckData> decks;

  const _DeckGrid({required this.decks});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: decks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final deck = decks[index];
        return GestureDetector(
          onTap: () {
            AppScope.of(context).setActiveDeck(deck.id);
            Navigator.pushNamed(context, AppRoutes.iniciar);
          },
          // Long-press abre el menú de visibilidad / reportar para que el
          // usuario pueda compartir el mazo o, si lo ve en comunidad, marcarlo.
          onLongPress: () => _showDeckActionsSheet(context, deck),
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.all(8),
            color: const Color(0x10FFFFFF),
            border: Border.all(color: const Color(0x24FFFFFF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DeckThumb(deck.icon),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: RefColors.sun,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          (4 + deck.retention / 100).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: RefColors.sun,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  deck.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${deck.cards.length} tarjetas',
                  style: const TextStyle(fontSize: 10, color: RefColors.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

