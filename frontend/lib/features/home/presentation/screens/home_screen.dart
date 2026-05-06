import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/layout/responsive.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/core/theme/theme_provider.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/home/data/achievements_provider.dart';
import 'package:memorizar/features/home/data/models/achievement_badge.dart';
import 'package:memorizar/features/home/data/models/reinforcement_suggestion.dart';
import 'package:memorizar/features/home/data/reinforcement_suggestion_provider.dart';
import 'package:memorizar/features/home/data/stats_provider.dart';
import 'package:memorizar/features/home/presentation/widgets/activity_heatmap.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);
    final totalDueAsync = ref.watch(totalDueTodayProvider);
    final streakAsync = ref.watch(streakProvider);
    final suggestionAsync = ref.watch(reinforcementSuggestionProvider);
    final reinforcementProgress = ref.watch(reinforcementProgressProvider);
    final cooperativeFollowUp = ref.watch(cooperativeFollowUpProvider);
    final remindersEnabled = ref.watch(smartReminderOptInProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final theme = Theme.of(context);
    final isWide = Responsive.isWide(context);

    final decks = decksAsync.valueOrNull ?? [];
    final totalDue = totalDueAsync.valueOrNull ?? 0;
    final streak = streakAsync.valueOrNull ?? 0;
    final suggestion = suggestionAsync.valueOrNull;
    final achievements = achievementsAsync.valueOrNull ?? const <AchievementBadge>[];
    final now = DateTime.now();
    final recentHistory = reinforcementProgress.history
        .where(
          (entry) =>
              entry.completedAt.year == now.year &&
              entry.completedAt.month == now.month &&
              entry.completedAt.day == now.day,
        )
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ContentWidth(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(theme: theme)),
              SliverToBoxAdapter(
                child: isWide
                    ? _WideLayout(
                        totalDue: totalDue,
                        decks: decks,
                        theme: theme,
                        streak: streak,
                        suggestion: remindersEnabled ? suggestion : null,
                        cooperativeFollowUp: cooperativeFollowUp,
                        remindersEnabled: remindersEnabled,
                        recentHistory: recentHistory,
                        achievements: achievements,
                      )
                    : _NarrowLayout(
                        totalDue: totalDue,
                        decks: decks,
                        theme: theme,
                        streak: streak,
                        suggestion: remindersEnabled ? suggestion : null,
                        cooperativeFollowUp: cooperativeFollowUp,
                        remindersEnabled: remindersEnabled,
                        recentHistory: recentHistory,
                        achievements: achievements,
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

// ── Wide layout (tablet+desktop): streak left, decks right ───────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.totalDue,
    required this.decks,
    required this.theme,
    required this.streak,
    required this.suggestion,
    required this.cooperativeFollowUp,
    required this.remindersEnabled,
    required this.recentHistory,
    required this.achievements,
  });
  final int totalDue;
  final List<Deck> decks;
  final ThemeData theme;
  final int streak;
  final ReinforcementSuggestion? suggestion;
  final CooperativeFollowUpState? cooperativeFollowUp;
  final bool remindersEnabled;
  final List<ReinforcementHistoryEntry> recentHistory;
  final List<AchievementBadge> achievements;

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
                if (!remindersEnabled) ...[
                  const SizedBox(height: 16),
                  const _ReminderOptInCard(),
                ] else if (suggestion != null) ...[
                  const SizedBox(height: 16),
                  _ReinforcementCard(suggestion: suggestion!),
                ],
                if (cooperativeFollowUp != null) ...[
                  const SizedBox(height: 16),
                  _CooperativeFollowUpCard(entry: cooperativeFollowUp!),
                ],
                if (recentHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RecentReinforcementHistory(entries: recentHistory, decks: decks),
                ],
                if (achievements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AchievementsCard(achievements: achievements),
                ],
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
  const _NarrowLayout({
    required this.totalDue,
    required this.decks,
    required this.theme,
    required this.streak,
    required this.suggestion,
    required this.cooperativeFollowUp,
    required this.remindersEnabled,
    required this.recentHistory,
    required this.achievements,
  });
  final int totalDue;
  final List<Deck> decks;
  final ThemeData theme;
  final int streak;
  final ReinforcementSuggestion? suggestion;
  final CooperativeFollowUpState? cooperativeFollowUp;
  final bool remindersEnabled;
  final List<ReinforcementHistoryEntry> recentHistory;
  final List<AchievementBadge> achievements;

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
        if (!remindersEnabled)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _ReminderOptInCard(),
          )
        else if (suggestion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _ReinforcementCard(suggestion: suggestion!),
          ),
        if (cooperativeFollowUp != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _CooperativeFollowUpCard(entry: cooperativeFollowUp!),
          ),
        if (recentHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _RecentReinforcementHistory(entries: recentHistory, decks: decks),
          ),
        if (achievements.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _AchievementsCard(achievements: achievements),
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
                      fontWeight: FontWeight.w700,
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

class _ReinforcementCard extends ConsumerWidget {
  const _ReinforcementCard({required this.suggestion});

  final ReinforcementSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progressNotifier = ref.read(reinforcementProgressProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tips_and_updates_rounded, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ruta de refuerzo', style: theme.textTheme.titleMedium),
                    Text(
                      '${suggestion.deckName} • ${suggestion.modeLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(suggestion.reason, style: theme.textTheme.bodyMedium),
          if (suggestion.weakestExerciseLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'Refuerza primero: ${suggestion.weakestExerciseLabel}',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Ruta sugerida',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          _RouteStepChip(step: suggestion.primaryRoute, index: 1),
          if (suggestion.secondaryRoute != null) ...[
            const SizedBox(height: 8),
            _RouteStepChip(step: suggestion.secondaryRoute!, index: 2),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(suggestion.primaryRoute.routePath),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(suggestion.ctaLabel),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => progressNotifier.markRouteCompleted(
                deckId: suggestion.deckId,
                routeLabel: suggestion.primaryRoute.label,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Marcar este paso como hecho'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CooperativeFollowUpCard extends ConsumerWidget {
  const _CooperativeFollowUpCard({required this.entry});

  final CooperativeFollowUpState entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(entry.title, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                onPressed: () => ref.read(cooperativeFollowUpProvider.notifier).clear(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Ocultar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'Esta sugerencia apareció después de tu última sesión cooperativa.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _RouteStepChip extends StatelessWidget {
  const _RouteStepChip({required this.step, required this.index});

  final ReinforcementRouteStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$index', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(step.description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReinforcementHistory extends StatelessWidget {
  const _RecentReinforcementHistory({
    required this.entries,
    required this.decks,
  });

  final List<ReinforcementHistoryEntry> entries;
  final List<Deck> decks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final deckNames = {for (final deck in decks) deck.id: deck.name};
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pasos completados hoy', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${entry.routeLabel} en ${deckNames[entry.deckId] ?? entry.deckId} · ${_timeAgoLabel(entry.completedAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderOptInCard extends ConsumerWidget {
  const _ReminderOptInCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recordatorios inteligentes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'La app puede sugerirte cuándo volver y si te conviene cards, ejercicios o ambos. Solo se activan si tú lo aceptas.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(smartReminderOptInProvider.notifier).setEnabled(true),
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('Activar sugerencias'),
          ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({required this.achievements});

  final List<AchievementBadge> achievements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievements.where((badge) => badge.unlocked).take(4).toList();
    if (unlocked.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rachas y logros', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...unlocked.map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(badge.title, style: theme.textTheme.titleSmall),
                        Text(badge.description, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgoLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'justo ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${deck.dueToday} hoy',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
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
