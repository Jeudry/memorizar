import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/cards/presentation/providers/cards_consolidations_provider.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';

class CardsSetupScreen extends ConsumerWidget {
  const CardsSetupScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckByIdProvider(deckId));
    final itemsAsync = ref.watch(itemsForDeckProvider(deckId));
    final consolidationsAsync = ref.watch(recentCardsDeckConsolidationsProvider(deckId));
    final deck = deckAsync.valueOrNull;
    final items = itemsAsync.valueOrNull ?? const [];
    final consolidations = consolidationsAsync.valueOrNull ?? const [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = deck == null
        ? AppColors.info
        : AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length];
    final supportAccent = _supportAccentFor(deck?.type, accent);

    return Scaffold(
      appBar: AppBar(title: const Text('Modo Cards')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        supportAccent.withValues(alpha: 0.12),
                        accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck?.name ?? 'Deck', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Refuerza un conjunto completo con ejercicios ligeros y generales.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72)),
                      ),
                      if (deck != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _CardsModePill(label: deck.type.label, color: supportAccent),
                            _CardsModePill(label: _deckMoodLabel(deck.type), color: accent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _deckMoodDescription(deck.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.76),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _CardsModePill(label: 'Flashcards clásicas', color: accent),
                          _CardsModePill(label: 'Emparejar referencia', color: supportAccent),
                          _CardsModePill(label: 'Detectar intruso', color: AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: items.isEmpty ? null : () => context.push('/decks/$deckId/cards/session'),
                        icon: const Icon(Icons.style_rounded),
                        label: Text(items.isEmpty ? 'No hay items' : 'Iniciar modo cards'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (consolidations.isNotEmpty) ...[
                  Text('Progreso reciente en cards', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _CardsProgressTile(
                    averageScore: consolidations
                            .map((entry) => entry.averageScore)
                            .fold<double>(0, (sum, value) => sum + value) /
                        consolidations.length,
                    lastPractice: consolidations.first.createdAt,
                    weakestLabel: _labelForCardsExercise(consolidations.first.weakestExerciseType),
                  ),
                  const SizedBox(height: 20),
                ],
                Text('Cómo funciona', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                const _HowItWorksTile(
                  title: 'Flashcards',
                  description: 'Revela cada item rápidamente para activar memoria general.',
                ),
                const SizedBox(height: 12),
                const _HowItWorksTile(
                  title: 'Emparejar',
                  description: 'Relaciona referencias con contenidos cercanos para evitar confusiones entre vecinos.',
                ),
                const SizedBox(height: 12),
                const _HowItWorksTile(
                  title: 'Intruso',
                  description: 'Detecta qué card no pertenece al bloque actual.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _labelForCardsExercise(String? storageValue) {
  switch (storageValue) {
    case 'flashcards':
      return 'Flashcards clásicas';
    case 'matching_reference':
      return 'Emparejar referencia';
    case 'detect_intruder':
      return 'Detectar intruso';
    default:
      return null;
  }
}

class _CardsModePill extends StatelessWidget {
  const _CardsModePill({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _HowItWorksTile extends StatelessWidget {
  const _HowItWorksTile({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CardsProgressTile extends StatelessWidget {
  const _CardsProgressTile({
    required this.averageScore,
    required this.lastPractice,
    this.weakestLabel,
  });

  final double averageScore;
  final DateTime lastPractice;
  final String? weakestLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promedio reciente ${(averageScore * 100).round()}%',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            weakestLabel == null
                ? 'Última sesión ${_daysAgoLabel(lastPractice)}.'
                : 'Última sesión ${_daysAgoLabel(lastPractice)}. Lo más flojo fue $weakestLabel.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _daysAgoLabel(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'hoy';
  if (days == 1) return 'hace 1 día';
  return 'hace $days días';
}

Color _supportAccentFor(DeckType? type, Color accent) {
  switch (type) {
    case DeckType.bible:
      return const Color(0xFFD4A017);
    case DeckType.language:
      return const Color(0xFF14B8A6);
    case DeckType.general:
      return const Color(0xFFEC4899);
    case null:
      return accent;
  }
}

String _deckMoodLabel(DeckType type) {
  switch (type) {
    case DeckType.bible:
      return 'Sereno';
    case DeckType.language:
      return 'Ágil';
    case DeckType.general:
      return 'Claro';
  }
}

String _deckMoodDescription(DeckType type) {
  switch (type) {
    case DeckType.bible:
      return 'En cards conviene repasar el conjunto sin perder ritmo ni cadencia entre referencias vecinas.';
    case DeckType.language:
      return 'Aquí ayuda mucho reaccionar rápido y no pensarlo demasiado entre una card y otra.';
    case DeckType.general:
      return 'Busca estructura limpia: detectar rápido qué pertenece y qué no pertenece al bloque.';
  }
}
