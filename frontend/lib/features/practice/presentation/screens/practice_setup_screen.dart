import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/cards/presentation/providers/cards_consolidations_provider.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/decks/presentation/providers/deck_services_provider.dart';
import 'package:memorizar/features/cards/data/models/cards_consolidation_record.dart';
import 'package:memorizar/features/practice/data/models/adaptive_practice_recommendation.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/exercise_consolidation_record.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_consolidations_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_goals_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_plans_provider.dart';

class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<PracticeSetupScreen> createState() =>
      _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen>
    with SingleTickerProviderStateMixin {
  MemorizationDifficulty _difficulty = MemorizationDifficulty.beginner;
  PracticeObjective _objective = PracticeObjective.deep;
  bool _creatingPlan = false;
  bool _weakOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckByIdProvider(widget.deckId));
    final itemsAsync = ref.watch(itemsForDeckProvider(widget.deckId));
    final goalsAsync = ref.watch(memorizationGoalsProvider(widget.deckId));
    final consolidationsAsync = ref.watch(
      recentDeckConsolidationsProvider(widget.deckId),
    );
    final cardsConsolidationsAsync = ref.watch(
      recentCardsDeckConsolidationsProvider(widget.deckId),
    );
    final plansAsync = ref.watch(memorizationPlansProvider(widget.deckId));
    final deck = deckAsync.valueOrNull;
    final items = itemsAsync.valueOrNull ?? [];
    final plans = plansAsync.valueOrNull ?? [];
    final goals = goalsAsync.valueOrNull ?? [];
    final consolidations =
        consolidationsAsync.valueOrNull ?? <ExerciseConsolidationRecord>[];
    final cardsConsolidations =
        cardsConsolidationsAsync.valueOrNull ?? <CardsConsolidationRecord>[];
    final accent = deck != null
        ? AppColors.deckAccents[deck.accentColorIndex %
              AppColors.deckAccents.length]
        : AppColors.indigo;

    final recommendation = deck == null
        ? null
        : _buildRec(items.length, consolidations, cardsConsolidations);

    return Scaffold(
      appBar: AppBar(
        title: Text(deck?.name ?? 'Práctica'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Práctica'),
            Tab(text: 'Metas'),
            Tab(text: 'Progreso'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: TabBarView(
              controller: _tabController,
              children: [
                _PracticeTab(
                  deckId: widget.deckId,
                  items: items,
                  difficulty: _difficulty,
                  objective: _objective,
                  onDifficultyChanged: (d) => setState(() => _difficulty = d),
                  onObjectiveChanged: (o) => setState(() => _objective = o),
                  accent: accent,
                  recommendation: recommendation,
                ),
                _GoalsAndPlansTab(
                  goals: goals,
                  plans: plans,
                  itemsLength: items.length,
                  objective: _objective,
                  difficulty: _difficulty,
                  weakOnly: _weakOnly,
                  accent: accent,
                  onCreateGoal: _createGoal,
                  deckId: widget.deckId,
                ),
                _ProgressTab(
                  consolidations: consolidations,
                  cardsConsolidations: cardsConsolidations,
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AdaptivePracticeRecommendation _buildRec(
    int totalItems,
    List<ExerciseConsolidationRecord> exerciseConsolidations,
    List<CardsConsolidationRecord> cardsConsolidations,
  ) {
    if (totalItems == 0) {
      return AdaptivePracticeRecommendation(
        objective: PracticeObjective.deep,
        difficulty: MemorizationDifficulty.beginner,
        weakOnly: false,
        recommendedMinutes: 10,
        targetStepCount: 8,
        reason: 'Agrega items al deck.',
        coachHint: 'Sesión ligera para empezar.',
        headline: 'Primera práctica',
      );
    }
    final avgExercise = exerciseConsolidations.isEmpty
        ? 0.5
        : exerciseConsolidations
                  .map((c) => c.averageScore)
                  .reduce((a, b) => a + b) /
              exerciseConsolidations.length;
    final weak = exerciseConsolidations.any((c) => c.averageScore < 0.6);
    return AdaptivePracticeRecommendation(
      objective: avgExercise < 0.65
          ? PracticeObjective.deep
          : PracticeObjective.quick,
      difficulty: avgExercise < 0.6
          ? MemorizationDifficulty.beginner
          : (avgExercise < 0.8
                ? MemorizationDifficulty.intermediate
                : MemorizationDifficulty.expert),
      weakOnly: weak,
      recommendedMinutes: (totalItems * 1.2).round(),
      targetStepCount: totalItems.clamp(4, 12),
      reason: 'Según ${exerciseConsolidations.length} sesiones.',
      coachHint: 'Mantén consistencia.',
      headline: 'Sugerencia',
    );
  }

  Future<void> _createGoal({required int targetItems}) async {
    await ref
        .read(memorizationGoalsControllerProvider)
        .createGoal(
          deckId: widget.deckId,
          title: 'Dominar ${targetItems.clamp(1, 999)} items',
          objective: _objective.label,
          targetItems: targetItems,
          targetDate: DateTime.now().add(const Duration(days: 30)),
        );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.deckId,
    required this.items,
    required this.difficulty,
    required this.objective,
    required this.onDifficultyChanged,
    required this.onObjectiveChanged,
    required this.accent,
    this.recommendation,
  });

  final String deckId;
  final List<dynamic> items;
  final MemorizationDifficulty difficulty;
  final PracticeObjective objective;
  final void Function(MemorizationDifficulty) onDifficultyChanged;
  final void Function(PracticeObjective) onObjectiveChanged;
  final Color accent;
  final AdaptivePracticeRecommendation? recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final rec = recommendation;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (rec != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.headline, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${rec.objective.label} • ${rec.difficulty.label}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onObjectiveChanged(rec.objective);
                    onDifficultyChanged(rec.difficulty);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Objetivo',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PracticeObjective.values.map((obj) {
            final selected = obj == objective;
            return ChoiceChip(
              label: Text(obj.label),
              selected: selected,
              onSelected: (_) => onObjectiveChanged(obj),
              selectedColor: accent.withValues(alpha: 0.16),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          objective.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Dificultad',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: MemorizationDifficulty.values.map((d) {
            final selected = d == difficulty;
            return InkWell(
              onTap: () => onDifficultyChanged(d),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.12) : cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? accent : cs.outline,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_shortDesc(d), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: items.isEmpty
              ? null
              : () => context.push(
                  '/decks/$deckId/practice/session?difficulty=${difficulty.name}&objective=${objective.name}&weakOnly=false',
                ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Empezar'),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  String _shortDesc(MemorizationDifficulty d) {
    switch (d) {
      case MemorizationDifficulty.beginner:
        return 'Con guía completa';
      case MemorizationDifficulty.intermediate:
        return 'Más directo';
      case MemorizationDifficulty.expert:
        return 'Mínimo apoyo';
    }
  }
}

class _GoalsAndPlansTab extends StatelessWidget {
  const _GoalsAndPlansTab({
    required this.goals,
    required this.plans,
    required this.itemsLength,
    required this.objective,
    required this.difficulty,
    required this.weakOnly,
    required this.accent,
    required this.onCreateGoal,
    required this.deckId,
  });

  final List<dynamic> goals;
  final List<dynamic> plans;
  final int itemsLength;
  final PracticeObjective objective;
  final MemorizationDifficulty difficulty;
  final bool weakOnly;
  final Color accent;
  final Future<void> Function({required int targetItems}) onCreateGoal;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Metas',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (goals.isEmpty)
          _EmptyState(
            icon: Icons.flag_outlined,
            text: 'Sin metas activas. Crea una para darle dirección.',
          )
        else
          ...goals
              .take(5)
              .map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ItemCard(
                    title: goal.title,
                    subtitle:
                        '${goal.targetItems} items${goal.targetDate == null ? '' : ' • ${goal.targetDate!.day}/${goal.targetDate!.month}'}',
                    accent: accent,
                    icon: Icons.flag_rounded,
                  ),
                ),
              ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => onCreateGoal(targetItems: itemsLength.clamp(5, 60)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear meta'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Planes',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          _EmptyState(
            icon: Icons.library_books_outlined,
            text: 'No hay planes guardados.',
          )
        else
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ItemCard(
                title: plan.name,
                subtitle: '${plan.difficulty.label} • ${plan.itemCount} items',
                accent: accent,
                icon: Icons.library_books_rounded,
                trailing: FilledButton.tonalIcon(
                  onPressed: () => context.push(
                    '/decks/$deckId/practice/session?difficulty=${plan.difficulty.name}&objective=${objective.name}&weakOnly=$weakOnly&planId=${plan.id}',
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Iniciar'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({
    required this.consolidations,
    required this.cardsConsolidations,
    required this.accent,
  });

  final List<ExerciseConsolidationRecord> consolidations;
  final List<CardsConsolidationRecord> cardsConsolidations;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final allRecords = [
      ...consolidations.map(
        (c) => _RecordItem(
          label: '${c.difficulty.label} • ${(c.averageScore * 100).round()}%',
          subtitle: '${c.totalMistakes} fallas',
          score: c.averageScore,
        ),
      ),
      ...cardsConsolidations.map(
        (c) => _RecordItem(
          label: 'Cards • ${(c.averageScore * 100).round()}%',
          subtitle: '${c.totalMistakes} fallas',
          score: c.averageScore,
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (allRecords.isEmpty)
          _EmptyState(
            icon: Icons.insights_outlined,
            text: 'Tu progreso aparecerá aquí después de completar sesiones.',
          )
        else
          ...allRecords
              .take(10)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ItemCard(
                    title: record.label,
                    subtitle: record.subtitle,
                    accent: accent,
                    icon: record.score >= 0.75
                        ? Icons.trending_up_rounded
                        : Icons.track_changes_rounded,
                  ),
                ),
              ),
      ],
    );
  }
}

class _RecordItem {
  final String label;
  final String subtitle;
  final double score;

  _RecordItem({
    required this.label,
    required this.subtitle,
    required this.score,
  });
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
