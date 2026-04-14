import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/layout/responsive.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';

class DecksScreen extends ConsumerWidget {
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);
    final theme = Theme.of(context);
    final isWide = Responsive.isWide(context);
    final crossCount = isWide ? 3 : 2;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: decksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (decks) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isWide ? 24 : 20, 24, isWide ? 24 : 20, 16),
                    child: Row(
                      children: [
                        Text('Mis Decks', style: theme.textTheme.headlineMedium),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => context.push('/decks/new'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Nuevo deck'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.1 : 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _DeckCard(deck: decks[i]),
                      childCount: decks.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length];
    final progress = deck.totalItems > 0 ? deck.learned / deck.totalItems : 0.0;

    return InkWell(
      onTap: () => context.push('/decks/${deck.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(deck.emoji ?? '📚', style: const TextStyle(fontSize: 28)),
                if (deck.dueToday > 0)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${deck.dueToday}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(deck.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text('${deck.totalItems} tarjetas', style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: accent.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toInt()}% dominado',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}