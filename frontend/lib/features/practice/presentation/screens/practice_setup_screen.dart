import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/prefs_provider.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/practice/data/models/memorization_difficulty.dart';
import 'package:memorizar/features/practice/data/models/cooperative_mode.dart';
import 'package:memorizar/features/practice/data/models/practice_objective.dart';
import 'package:memorizar/features/practice/presentation/providers/exercise_consolidations_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/journey_planner_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_goals_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_journeys_provider.dart';
import 'package:memorizar/features/practice/presentation/providers/memorization_plans_provider.dart';

class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  MemorizationDifficulty _difficulty = MemorizationDifficulty.beginner;
  PracticeObjective _objective = PracticeObjective.deep;
  bool _creatingPlan = false;
  bool _weakOnly = false;
  int _cooperativePlayers = 1;
  CooperativeMode _cooperativeMode = CooperativeMode.solo;

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckByIdProvider(widget.deckId));
    final itemsAsync = ref.watch(itemsForDeckProvider(widget.deckId));
    final plansAsync = ref.watch(memorizationPlansProvider(widget.deckId));
    final goalsAsync = ref.watch(memorizationGoalsProvider(widget.deckId));
    final journeysAsync = ref.watch(memorizationJourneysProvider(widget.deckId));
    final consolidationsAsync = ref.watch(recentDeckConsolidationsProvider(widget.deckId));
    final remindersEnabled = ref.watch(smartReminderOptInProvider);
    final deck = deckAsync.valueOrNull;
    final items = itemsAsync.valueOrNull ?? const [];
    final journeyOptions = ref.read(journeyPlannerProvider).buildOptions(totalItems: items.length);
    final plans = plansAsync.valueOrNull ?? const [];
    final goals = goalsAsync.valueOrNull ?? const [];
    final journeys = journeysAsync.valueOrNull ?? const [];
    final consolidations = consolidationsAsync.valueOrNull ?? const [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = deck != null
        ? AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length]
        : AppColors.indigo;

    return Scaffold(
      appBar: AppBar(title: const Text('Memorizar con ejercicios')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.24), accent.withValues(alpha: 0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withValues(alpha: 0.24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck?.name ?? 'Deck', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Elige si quieres velocidad, profundidad, duelo o examen total. También puedes concentrarte solo en tus debilidades.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Objetivo', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: PracticeObjective.values.map((objective) {
                          final selected = objective == _objective;
                          return ChoiceChip(
                            label: Text(objective.label),
                            selected: selected,
                            onSelected: (_) => setState(() => _objective = objective),
                            selectedColor: accent.withValues(alpha: 0.16),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(_objective.description, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 18),
                      Text('Dificultad', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: MemorizationDifficulty.values.map((difficulty) {
                          final selected = difficulty == _difficulty;
                          return InkWell(
                            onTap: () => setState(() => _difficulty = difficulty),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 220,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: selected ? accent.withValues(alpha: 0.12) : cs.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected ? accent : cs.outline,
                                  width: selected ? 1.4 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    difficulty.label,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? accent : cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _descriptionFor(difficulty),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        value: _weakOnly,
                        onChanged: (value) => setState(() => _weakOnly = value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reforzar solo débiles'),
                        subtitle: const Text('Recorta la sesión a las dinámicas donde vienes cayendo más.'),
                      ),
                      SwitchListTile.adaptive(
                        value: remindersEnabled,
                        onChanged: (value) => ref.read(smartReminderOptInProvider.notifier).setEnabled(value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aceptar recordatorios inteligentes'),
                        subtitle: const Text('La app podrá sugerirte cuándo volver y con qué enfoque.'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded),
                          const SizedBox(width: 8),
                          Text('Cooperativo local', style: theme.textTheme.titleSmall),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _cooperativePlayers,
                            items: const [1, 2, 3, 4]
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value == 1 ? 'Solo' : '$value personas'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _cooperativePlayers = value;
                                  if (value == 1) {
                                    _cooperativeMode = CooperativeMode.solo;
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (_cooperativePlayers > 1) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<CooperativeMode>(
                          initialValue: _cooperativeMode == CooperativeMode.solo ? CooperativeMode.relay : _cooperativeMode,
                          decoration: const InputDecoration(
                            labelText: 'Dinámica cooperativa',
                            border: OutlineInputBorder(),
                          ),
                          items: CooperativeMode.values
                              .where((mode) => mode != CooperativeMode.solo)
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _cooperativeMode = value);
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (_cooperativeMode == CooperativeMode.solo ? CooperativeMode.relay : _cooperativeMode).description,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: items.isEmpty
                                  ? null
                                  : () => context.push(
                                        '/decks/${widget.deckId}/practice/session?difficulty=${_difficulty.name}&objective=${_objective.name}&weakOnly=$_weakOnly&coop=$_cooperativePlayers&coopMode=${(_cooperativePlayers == 1 ? CooperativeMode.solo : _cooperativeMode).name}',
                                      ),
                              icon: const Icon(Icons.auto_awesome_rounded),
                              label: Text(_objective == PracticeObjective.quick ? 'Empezar rápido' : 'Empezar sesión'),
                              style: FilledButton.styleFrom(backgroundColor: accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: items.isEmpty || _creatingPlan ? null : () => _createPlan(context, items.length),
                              icon: _creatingPlan
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.playlist_add_rounded),
                              label: const Text('Guardar plan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Metas activas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (goals.isEmpty)
                  const _EmptyCard(
                    text: 'Todavía no hay metas. Crea una para empujar este deck hacia una fecha o cantidad concreta.',
                  )
                else
                  ...goals.take(3).map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MetaTile(
                            title: goal.title,
                            subtitle:
                                '${goal.targetItems} items${goal.targetDate == null ? '' : ' • antes de ${goal.targetDate!.day}/${goal.targetDate!.month}'}',
                            accent: accent,
                            icon: Icons.flag_rounded,
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: items.isEmpty ? null : () => _createGoal(targetItems: items.length.clamp(5, 60)),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Crear meta sugerida'),
                ),
                const SizedBox(height: 20),
                Text('Journeys grandes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (journeys.isEmpty)
                  const _EmptyCard(
                    text: 'Planifica algo grande, como completar un deck entero en una cantidad fija de días.',
                  )
                else
                  ...journeys.take(3).map(
                        (journey) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MetaTile(
                            title: journey.title,
                            subtitle:
                                '${journey.targetDays} días • ${journey.itemsPerDay} items/día • ${journey.targetItemCount} items',
                            accent: accent,
                            icon: Icons.timeline_rounded,
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                if (journeyOptions.isEmpty)
                  const _EmptyCard(
                    text: 'Agrega más items al deck para generar journeys grandes.',
                  )
                else
                  ...journeyOptions.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton.icon(
                        onPressed: () => _createJourney(items.length, days: option.targetDays),
                        icon: const Icon(Icons.timeline_rounded),
                        label: Text('${option.label} • ${option.summary}'),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text('Planes guardados', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (plansAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (plans.isEmpty)
                  const _EmptyCard(
                    text: 'Todavía no hay planes. Guarda uno para repetir esta misma secuencia luego.',
                  )
                else
                  ...plans.map((plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.library_books_rounded, color: accent),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plan.name, style: theme.textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${plan.difficulty.label} • ${plan.itemCount} items',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => context.push(
                                  '/decks/${widget.deckId}/practice/session?difficulty=${plan.difficulty.name}&objective=${_objective.name}&weakOnly=$_weakOnly&planId=${plan.id}',
                                ),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Iniciar'),
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 20),
                Text('Progreso reciente', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (consolidationsAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (consolidations.isEmpty)
                  const _EmptyCard(
                    text: 'Aquí verás tus consolidaciones recientes cuando completes algunas sesiones.',
                  )
                else
                  ...consolidations.take(5).map((record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record.difficulty.label} • ${(record.averageScore * 100).round()}%',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fallas ${record.totalMistakes}'
                                      '${record.weakestStepType == null ? '' : ' • Débil: ${record.weakestStepType!.label}'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                record.averageScore >= 0.75 ? Icons.trending_up_rounded : Icons.track_changes_rounded,
                                color: record.averageScore >= 0.75 ? AppColors.success : AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(MemorizationDifficulty difficulty) {
    switch (difficulty) {
      case MemorizationDifficulty.beginner:
        return 'Recorrido completo con guía, grabación, completado, primera letra y voz.';
      case MemorizationDifficulty.intermediate:
        return 'Recorta pasos introductorios y sube más rápido a examen.';
      case MemorizationDifficulty.expert:
        return 'Va directo a completar, primera letra y recitación final.';
    }
  }

  Future<void> _createPlan(BuildContext context, int totalItems) async {
    setState(() => _creatingPlan = true);
    final items = await ref.read(itemsForDeckProvider(widget.deckId).future);
    final service = ref.read(memorizationPlansServiceProvider);
    final planId = await service.createQuickPlan(
      deckId: widget.deckId,
      difficulty: _difficulty,
      items: items,
    );
    ref.invalidate(memorizationPlansProvider(widget.deckId));
    if (!context.mounted) return;
    setState(() => _creatingPlan = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan creado con $totalItems items.')),
    );
    context.push(
      '/decks/${widget.deckId}/practice/session?difficulty=${_difficulty.name}&objective=${_objective.name}&weakOnly=$_weakOnly&coop=$_cooperativePlayers&coopMode=${(_cooperativePlayers == 1 ? CooperativeMode.solo : _cooperativeMode).name}&planId=$planId',
    );
  }

  Future<void> _createGoal({required int targetItems}) async {
    await ref.read(memorizationGoalsControllerProvider).createGoal(
          deckId: widget.deckId,
          title: 'Dominar ${targetItems.clamp(1, 999)} items',
          objective: _objective.label,
          targetItems: targetItems,
          targetDate: DateTime.now().add(const Duration(days: 30)),
        );
  }

  Future<void> _createJourney(int targetItemCount, {required int days}) async {
    final targetDays = days;
    final itemsPerDay = (targetItemCount / targetDays).ceil().clamp(1, 999);
    await ref.read(memorizationJourneysControllerProvider).createJourney(
          deckId: widget.deckId,
          title: 'Completar en $targetDays días',
          targetDays: targetDays,
          itemsPerDay: itemsPerDay,
          targetItemCount: targetItemCount,
          objective: _objective.label,
        );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline),
      ),
      child: Text(text),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
