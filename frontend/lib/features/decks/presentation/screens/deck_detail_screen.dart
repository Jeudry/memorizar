import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/features/decks/data/models/deck_memorization_health.dart';
import 'package:memorizar/features/decks/data/models/item_mastery_record.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/deck_memorization_health_provider.dart';
import 'package:memorizar/features/decks/presentation/providers/item_mastery_map_provider.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/home/data/models/reinforcement_suggestion.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckByIdProvider(deckId));
    final items = ref.watch(itemsForDeckProvider(deckId));
    final dueItems = ref.watch(dueItemsProvider(deckId));
    final masteryAsync = ref.watch(itemMasteryMapProvider(deckId));

    final deckValue = deck.valueOrNull;
    final itemsValue = items.valueOrNull ?? [];
    final dueItemsValue = dueItems.valueOrNull ?? [];
    final mastery = masteryAsync.valueOrNull ?? const <ItemMasteryRecord>[];
    final healthAsync = ref.watch(deckMemorizationHealthProvider(deckId));
    final health = healthAsync.valueOrNull;

    if (deckValue == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = AppColors.deckAccents[deckValue.accentColorIndex % AppColors.deckAccents.length];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 208,
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
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deckValue.emoji ?? '📚', style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          deckValue.name,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          deckValue.description,
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
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => context.push('/decks/$deckId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                onPressed: () => _confirmDeleteDeck(context, ref, deckId),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _StatChip(label: 'Total', value: '${deckValue.totalItems}', color: cs.primary),
                  const SizedBox(width: 10),
                  _StatChip(label: 'Hoy', value: '${dueItemsValue.length}', color: AppColors.warning),
                  const SizedBox(width: 10),
                  _StatChip(label: 'Dominadas', value: '${deckValue.learned}', color: AppColors.success),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: health == null
                  ? const SizedBox.shrink()
                  : _DeckHealthCard(health: health, accent: accent),
            ),
          ),
          if (mastery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _MasteryMapCard(records: mastery, accent: accent),
              ),
            ),
          if (dueItemsValue.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push('/review/$deckId'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Repasar ${dueItemsValue.length} tarjetas de hoy'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/decks/$deckId/practice'),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Memorizar con ejercicios'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/decks/$deckId/cards'),
                      icon: const Icon(Icons.style_rounded),
                      label: const Text('Modo Cards'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/decks/$deckId/practice'),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Memorizar con ejercicios'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/decks/$deckId/cards'),
                      icon: const Icon(Icons.style_rounded),
                      label: const Text('Modo Cards'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text('Todas las tarjetas', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: accent),
                    onPressed: () => context.push('/decks/$deckId/items/new'),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ItemRow(item: itemsValue[i], accent: accent, deckId: deckId),
              childCount: itemsValue.length,
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

class _DeckHealthCard extends StatelessWidget {
  const _DeckHealthCard({
    required this.health,
    required this.accent,
  });

  final DeckMemorizationHealth health;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
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
                    Text('Salud de memorización', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      health.statusLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(health.healthScore * 100).round()}%',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: health.healthScore,
            minHeight: 8,
            backgroundColor: cs.outline.withValues(alpha: 0.24),
            valueColor: AlwaysStoppedAnimation(accent),
          ),
          const SizedBox(height: 14),
          Text(health.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ModeHealthPill(
                  label: 'Ejercicios',
                  score: health.exerciseAverageScore,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeHealthPill(
                  label: 'Cards',
                  score: health.cardsAverageScore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Siguiente mejor paso',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          _RouteSummaryTile(step: health.primaryRoute, accent: accent),
          if (health.secondaryRoute != null) ...[
            const SizedBox(height: 8),
            _RouteSummaryTile(step: health.secondaryRoute!, accent: accent.withValues(alpha: 0.72)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(health.primaryRoute.routePath),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text('Empezar ${health.primaryRoute.label.toLowerCase()}'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          if (health.secondaryRoute != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(health.secondaryRoute!.routePath),
                icon: const Icon(Icons.layers_rounded),
                label: Text('Luego seguir con ${health.secondaryRoute!.label.toLowerCase()}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeHealthPill extends StatelessWidget {
  const _ModeHealthPill({
    required this.label,
    required this.score,
  });

  final String label;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            score == null ? 'Sin historial' : '${(score! * 100).round()}%',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryTile extends StatelessWidget {
  const _RouteSummaryTile({
    required this.step,
    required this.accent,
  });

  final ReinforcementRouteStep step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(step.description, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MasteryMapCard extends StatelessWidget {
  const _MasteryMapCard({
    required this.records,
    required this.accent,
  });

  final List<ItemMasteryRecord> records;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mapa de dominio', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Cada item muestra qué tan dominado está según tus consolidaciones recientes.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: records.take(12).map((record) {
              final color = switch (record.label) {
                'Fuerte' => AppColors.success,
                'En progreso' => AppColors.warning,
                'Débil' => AppColors.error,
                _ => cs.outline,
              };
              return Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.front,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(record.label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
                    const SizedBox(height: 4),
                    Text('${(record.score * 100).round()}%', style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
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
            Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.accent, required this.deckId});
  final Item item;
  final Color accent;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: () => context.push('/decks/$deckId/items/${item.id}'),
      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Practicar este item',
              onPressed: () => context.push('/decks/$deckId/practice/session?difficulty=beginner&itemId=${item.id}'),
              icon: Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteDeck(BuildContext context, WidgetRef ref, String deckId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar deck?'),
      content: const Text('Se eliminarán todas las tarjetas. Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final db = ref.read(databaseProvider);
    await db.deleteDeck(deckId);
    if (context.mounted) context.pop();
  }
}
