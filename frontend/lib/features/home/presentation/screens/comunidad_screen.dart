// Generado del refactor de ui_screens.dart.
// ComunidadScreen + helpers.
part of '../ui_screens.dart';

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>>? _results;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
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
              for (final r in _results!) _CommunityHit(share: r, onImport: () => _import(r)),
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
      ),
    );
  }
}

class _CommunityHit extends StatelessWidget {
  final Map<String, dynamic> share;
  final VoidCallback onImport;
  const _CommunityHit({required this.share, required this.onImport});

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

