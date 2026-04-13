import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/layout/responsive.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/core/theme/theme_provider.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/home/data/stats_provider.dart';
import 'package:memorizar/features/home/presentation/widgets/activity_heatmap.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider);
    final totalDue = ref.watch(totalDueTodayProvider);
    final streak = ref.watch(streakProvider);
    final theme = Theme.of(context);
    final isWide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ContentWidth(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(theme: theme)),
              SliverToBoxAdapter(
                child: isWide
                    ? _WideLayout(totalDue: totalDue, decks: decks, theme: theme, streak: streak)
                    : _NarrowLayout(totalDue: totalDue, decks: decks, theme: theme, streak: streak),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wide layout (tablet+desktop): streak left, decks right ───────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.totalDue, required this.decks, required this.theme, required this.streak});
  final int totalDue;
  final List<Deck> decks;
  final ThemeData theme;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: streak + stats + heatmap
          SizedBox(
            width: 280,
            child: Column(
              children: [
                _StreakBanner(totalDue: totalDue, streak: streak),
                const SizedBox(height: 16),
                _StatsRow(decks: decks),
                const SizedBox(height: 16),
                const ActivityHeatmap(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column: decks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tus decks', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...decks.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HomeDeckRow(deck: d),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrow layout (mobile): stacked ──────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.totalDue, required this.decks, required this.theme, required this.streak});
  final int totalDue;
  final List<Deck> decks;
  final ThemeData theme;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _StreakBanner(totalDue: totalDue, streak: streak),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: const ActivityHeatmap(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text('Tus decks', style: theme.textTheme.titleMedium),
        ),
        ...decks.map((d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: _HomeDeckRow(deck: d),
            )),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.isWide(context) ? 24 : 20,
        24,
        Responsive.isWide(context) ? 24 : 20,
        0,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 2),
              Text('Memorizar', style: theme.textTheme.headlineMedium),
            ],
          ),
          const Spacer(),
          Consumer(builder: (context, ref, _) {
            final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
            return Row(children: [
              InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppColors.indigo),
              ),
            ]);
          }),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días ☀️';
    if (h < 18) return 'Buenas tardes 🌤️';
    return 'Buenas noches 🌙';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.decks});
  final List<Deck> decks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalCards = decks.fold(0, (s, d) => s + d.totalItems);
    final learned = decks.fold(0, (s, d) => s + d.learned);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Decks', value: '${decks.length}', color: AppColors.indigo),
          _divider(),
          _StatItem(label: 'Tarjetas', value: '$totalCards', color: AppColors.info),
          _divider(),
          _StatItem(label: 'Dominadas', value: '$learned', color: AppColors.success),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2));
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.totalDue, required this.streak});
  final int totalDue;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo, Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalDue > 0 ? '$totalDue tarjetas te esperan' : '¡Al día! 🎉',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalDue > 0
                          ? 'Repasa para mantener tu racha'
                          : 'Vuelve mañana para continuar',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  Text(
                    '$streak',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text('días',
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
          if (totalDue > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/decks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.indigo,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Empezar repaso'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeDeckRow extends StatelessWidget {
  const _HomeDeckRow({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent =
        AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length];

    return InkWell(
      onTap: () => context.push('/decks/${deck.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(deck.emoji ?? '📚',
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('${deck.totalItems} tarjetas',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (deck.dueToday > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${deck.dueToday} hoy',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
