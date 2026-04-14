import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckByIdProvider(deckId));
    final itemsAsync = ref.watch(itemsForDeckProvider(deckId));
    final dueItemsAsync = ref.watch(dueItemsProvider(deckId));

    final deck = deckAsync.valueOrNull;
    if (deck == null) {
      return deckAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (_) => const Scaffold(body: Center(child: Text('Deck no encontrado'))),
      );
    }

    final items = itemsAsync.valueOrNull ?? [];
    final dueItems = dueItemsAsync.valueOrNull ?? [];

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.emoji ?? '📚', style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          deck.name,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          deck.description,
                          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StatChip(label: 'Nuevas', value: '${deck.newCount}', color: cs.primary),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Aprendiendo', value: '${deck.learningCount}', color: AppColors.warning),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Dominadas', value: '${deck.reviewCount}', color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatChip(label: 'Ease avg', value: deck.averageEase.toStringAsFixed(1), color: cs.tertiary),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Total repasos', value: '${deck.totalReviews}', color: cs.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (dueItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FilledButton.icon(
                  onPressed: () => context.push('/review/$deckId'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Repasar ${dueItems.length} tarjetas de hoy'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text('Todas las tarjetas (${items.length})', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/decks/$deckId/items/new'),
                    icon: Icon(Icons.add_rounded, color: accent),
                    style: IconButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ItemRow(item: items[i], accent: accent),
              childCount: items.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.accent});
  final Item item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.isDue ? accent : accent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.front, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    item.back,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nueva',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}