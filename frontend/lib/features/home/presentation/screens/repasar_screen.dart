// Generado del refactor de ui_screens.dart.
// RepasarScreen + helpers.
part of '../ui_screens.dart';

class RepasarScreen extends StatelessWidget {
  const RepasarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dueCards = store.dueCards;
    final weakCount = dueCards.where((card) => card.retention < 60).length;
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
                      const TextSpan(text: ' están por caer bajo retención'),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTab(
                    'Por tarjeta · ${dueCards.length}',
                    active: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentTab('Por mazo · ${store.decks.length}'),
                ),
              ],
            ),
          ),
          const SectionHead('⚠ Tarjetas más débiles', action: 'Ver todas'),
          for (final group in _groupReviewCards(_attachDecks(dueCards, store)))
            _ReviewItem(
              group.icon,
              group.front,
              '${group.source} · ${group.totalLapses} ${group.totalLapses == 1 ? "fallo" : "fallos"}',
              '${group.avgRetention}%',
              urgent: group.avgRetention < 60,
              onTap: () => Navigator.pushNamed(context, AppRoutes.flashcards),
            ),
          const SectionHead('Mazos con retención baja'),
          for (final deck in store.decks.take(3))
            _DeckRetention(
              deck.icon,
              deck.title,
              '${deck.weakCount} débiles · ${deck.cards.length} tarjetas',
              deck.retention / 100,
            ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String text;
  final bool active;

  const _SegmentTab(this.text, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? HtmlRefColors.glassStrong : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active ? Border.all(color: HtmlRefColors.glassBorder) : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? RefColors.ink : RefColors.muted,
          ),
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String pct;
  final bool urgent;
  final VoidCallback? onTap;

  const _ReviewItem(
    this.emoji,
    this.title,
    this.subtitle,
    this.pct, {
    this.urgent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: urgent
              ? RefColors.urgent.withValues(alpha: .08)
              : RefColors.glassSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: urgent
                ? RefColors.urgent.withValues(alpha: .4)
                : RefColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: RefColors.glassStrong,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RefColors.border),
              ),
              child: Center(child: GlyphIcon(emoji, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: RefColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _PercentBadge(pct, urgent: urgent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '›',
              style: TextStyle(color: RefColors.muted, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final String pct;
  final bool urgent;

  const _PercentBadge(this.pct, {required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: urgent
            ? RefColors.urgent.withValues(alpha: .18)
            : RefColors.sun.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: urgent
              ? RefColors.urgent.withValues(alpha: .4)
              : RefColors.sun.withValues(alpha: .4),
        ),
      ),
      child: Text(
        pct,
        style: TextStyle(
          color: urgent ? RefColors.urgent : RefColors.sun,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeckRetention extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final double value;

  const _DeckRetention(this.emoji, this.title, this.subtitle, this.value);

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
        ],
      ),
    );
  }
}

