import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/home/data/stats_provider.dart';

class ActivityHeatmap extends ConsumerWidget {
  const ActivityHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    final streak = ref.watch(streakProvider);
    final totalReviews = ref.watch(totalReviewsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Build 9 weeks × 7 days grid (63 days), newest = bottom-right
    const weeks = 9;
    const days = 7;
    const total = weeks * days;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Actividad', style: theme.textTheme.titleSmall),
              const Spacer(),
              _StatBadge(label: '🔥 $streak días', color: AppColors.warning),
              const SizedBox(width: 8),
              _StatBadge(label: '$totalReviews repasos', color: AppColors.indigo),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (weekIndex) {
              return Padding(
                padding: EdgeInsets.only(right: weekIndex < weeks - 1 ? 4 : 0),
                child: Column(
                  children: List.generate(days, (dayIndex) {
                    final daysAgo = total - 1 - (weekIndex * days + dayIndex);
                    final count = activity[daysAgo] ?? 0;
                    final intensity = _intensity(count);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Tooltip(
                        message: count > 0 ? '$count repasos' : 'Sin repasos',
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200 + daysAgo * 2),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _cellColor(intensity, cs),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Menos', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              const SizedBox(width: 4),
              ...List.generate(4, (i) => Container(
                    margin: const EdgeInsets.only(right: 3),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _cellColor(i / 3, cs),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
              Text('Más', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  double _intensity(int count) {
    if (count == 0) return 0;
    if (count <= 3) return 0.25;
    if (count <= 6) return 0.5;
    if (count <= 9) return 0.75;
    return 1.0;
  }

  Color _cellColor(double intensity, ColorScheme cs) {
    if (intensity == 0) return cs.outline.withValues(alpha: 0.4);
    return AppColors.indigo.withValues(alpha: 0.2 + intensity * 0.8);
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
