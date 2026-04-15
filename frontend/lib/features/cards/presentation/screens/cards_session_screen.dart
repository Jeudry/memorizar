import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:memorizar/core/db/app_database.dart' show CardsConsolidationsCompanion;
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/cards/presentation/providers/cards_consolidations_provider.dart';
import 'package:memorizar/features/cards/presentation/providers/cards_services_provider.dart';
import 'package:memorizar/features/cards/services/cards_session_service.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';

class CardsSessionScreen extends ConsumerStatefulWidget {
  const CardsSessionScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<CardsSessionScreen> createState() => _CardsSessionScreenState();
}

class _CardsSessionScreenState extends ConsumerState<CardsSessionScreen> {
  int _stepIndex = 0;
  int _flashcardIndex = 0;
  bool _revealed = false;
  final Map<String, String> _matchingAnswers = {};
  String? _selectedIntruderId;
  int _score = 0;
  final Map<String, double> _stepScores = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckByIdProvider(widget.deckId));
    final itemsAsync = ref.watch(itemsForDeckProvider(widget.deckId));
    final deck = deckAsync.valueOrNull;
    final items = itemsAsync.valueOrNull ?? const <Item>[];
    final service = ref.read(cardsSessionServiceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = deck == null
        ? AppColors.info
        : AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length];

    if (deck == null || items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final flashcards = service.selectFlashcards(items);
    final matching = service.buildMatchingChallenge(items);
    final intruder = service.buildIntruderChallenge(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Cards'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LinearProgressIndicator(
                  value: (_stepIndex + 1) / 3,
                  minHeight: 6,
                  backgroundColor: cs.outline,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
                const SizedBox(height: 18),
                if (_stepIndex == 0)
                  _FlashcardsStep(
                    cards: flashcards,
                    accent: accent,
                    currentIndex: _flashcardIndex,
                    revealed: _revealed,
                    onReveal: () => setState(() => _revealed = true),
                    onNext: () {
                      if (_flashcardIndex >= flashcards.length - 1) {
                        setState(() {
                          _stepScores['flashcards'] = 1;
                          _stepIndex = 1;
                          _revealed = false;
                        });
                      } else {
                        setState(() {
                          _flashcardIndex += 1;
                          _revealed = false;
                        });
                      }
                    },
                  )
                else if (_stepIndex == 1)
                  _MatchingStep(
                    challenge: matching,
                    accent: accent,
                    answers: _matchingAnswers,
                    onPick: (itemId, content) => setState(() => _matchingAnswers[itemId] = content),
                    onSubmit: () {
                      final correct = matching.items
                          .where((item) => _matchingAnswers[item.id] == item.back)
                          .length;
                      setState(() {
                        _score += correct;
                        _stepScores['matching_reference'] = matching.items.isEmpty
                            ? 0
                            : correct / matching.items.length;
                        _stepIndex = 2;
                      });
                    },
                  )
                else if (_stepIndex == 2)
                  _IntruderStep(
                    challenge: intruder,
                    accent: accent,
                    selectedIntruderId: _selectedIntruderId,
                    onSelect: (itemId) => setState(() => _selectedIntruderId = itemId),
                    onSubmit: () => _completeSession(intruder: intruder),
                  )
                else
                  _CardsFinishedStep(
                    score: _score,
                    total: matching.items.length + 1,
                    deckName: deck.name,
                    weakestExerciseLabel: _labelForCardsExercise(_resolveWeakestStep()),
                    averageScore: _averageScore,
                    isSaving: _isSaving,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double get _averageScore {
    if (_stepScores.isEmpty) return 0;
    return _stepScores.values.reduce((a, b) => a + b) / _stepScores.length;
  }

  String? _resolveWeakestStep() {
    if (_stepScores.isEmpty) return null;
    return _stepScores.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  String? _resolveStrongestStep() {
    if (_stepScores.isEmpty) return null;
    return _stepScores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Future<void> _completeSession({required IntruderChallenge intruder}) async {
    if (_isSaving) return;
    final intruderScore = _selectedIntruderId == intruder.intruderId ? 1.0 : 0.0;
    if (intruderScore > 0) {
      _score += 1;
    }

    setState(() {
      _stepScores['detect_intruder'] = intruderScore;
      _isSaving = true;
    });

    final totalMistakes = _stepScores.values.fold<int>(
      0,
      (sum, score) => sum + ((1 - score) * 100).round(),
    );

    await ref.read(databaseProvider).saveCardsConsolidation(
          CardsConsolidationsCompanion.insert(
            deckId: widget.deckId,
            averageScore: _averageScore,
            totalMistakes: Value(totalMistakes),
            weakestExerciseType: Value(_resolveWeakestStep()),
            strongestExerciseType: Value(_resolveStrongestStep()),
          ),
        );

    ref.invalidate(recentCardsDeckConsolidationsProvider(widget.deckId));
    ref.invalidate(deckByIdProvider(widget.deckId));
    ref.invalidate(itemsForDeckProvider(widget.deckId));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _stepIndex = 3;
      });
    }
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

class _FlashcardsStep extends StatelessWidget {
  const _FlashcardsStep({
    required this.cards,
    required this.accent,
    required this.currentIndex,
    required this.revealed,
    required this.onReveal,
    required this.onNext,
  });

  final List<Item> cards;
  final Color accent;
  final int currentIndex;
  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final item = cards[currentIndex];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Text('Flashcards clásicas', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${currentIndex + 1}/${cards.length}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(item.front, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  revealed ? item.back : 'Toca revelar para ver el contenido.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: revealed ? null : onReveal,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Revelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: revealed ? onNext : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(currentIndex >= cards.length - 1 ? 'Seguir' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchingStep extends StatelessWidget {
  const _MatchingStep({
    required this.challenge,
    required this.accent,
    required this.answers,
    required this.onPick,
    required this.onSubmit,
  });

  final MatchingChallenge challenge;
  final Color accent;
  final Map<String, String> answers;
  final void Function(String itemId, String content) onPick;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emparejar referencia', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Relaciona cada referencia con su contenido correcto. Las opciones son cercanas para que el reto sea real.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          ...challenge.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.front, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: challenge.contents
                          .map(
                            (content) => ChoiceChip(
                              label: SizedBox(
                                width: 220,
                                child: Text(
                                  content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              selected: answers[item.id] == content,
                              selectedColor: accent.withValues(alpha: 0.2),
                              onSelected: (_) => onPick(item.id, content),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: answers.length == challenge.items.length ? onSubmit : null,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Validar emparejado'),
          ),
        ],
      ),
    );
  }
}

class _IntruderStep extends StatelessWidget {
  const _IntruderStep({
    required this.challenge,
    required this.accent,
    required this.selectedIntruderId,
    required this.onSelect,
    required this.onSubmit,
  });

  final IntruderChallenge challenge;
  final Color accent;
  final String? selectedIntruderId;
  final void Function(String itemId) onSelect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detectar intruso', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Una card no pertenece al bloque actual. Tócala.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          ...challenge.options.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSelect(item.id),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedIntruderId == item.id
                        ? accent.withValues(alpha: 0.14)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selectedIntruderId == item.id ? accent : cs.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.front, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(item.back, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: selectedIntruderId == null ? null : onSubmit,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Confirmar intruso'),
          ),
        ],
      ),
    );
  }
}

class _CardsFinishedStep extends StatelessWidget {
  const _CardsFinishedStep({
    required this.score,
    required this.total,
    required this.deckName,
    required this.averageScore,
    required this.isSaving,
    this.weakestExerciseLabel,
  });

  final int score;
  final int total;
  final String deckName;
  final double averageScore;
  final bool isSaving;
  final String? weakestExerciseLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.style_rounded, size: 46, color: AppColors.success),
          const SizedBox(height: 16),
          Text('Cards completado', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Terminaste el refuerzo general de $deckName con puntaje $score/$total.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Promedio de sesión ${(averageScore * 100).round()}%'
            '${weakestExerciseLabel == null ? '' : ' · Punto más débil: $weakestExerciseLabel'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isSaving ? null : () => context.pop(),
            child: Text(isSaving ? 'Guardando…' : 'Volver al deck'),
          ),
        ],
      ),
    );
  }
}
