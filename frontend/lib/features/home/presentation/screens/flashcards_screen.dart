// Generado del refactor de ui_screens.dart.
// FlashcardsScreen + PremiumScreen + helpers.
part of '../ui_screens.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final deck = store.activeDeck;
    final card = store.activeCard;
    final progress = (store.currentCardIndex + 1) / deck.cards.length;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlashcardsTopBar(title: deck.title),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: RefProgress(progress.clamp(.05, 1.0)),
          ),
          _FlashcardDeck(deck: deck, card: card, index: store.currentCardIndex),
          const SizedBox(height: 20),
          _FlashcardActions(
            onAgain: () => store.answerCurrentCard(false),
            onHard: () => store.answerCurrentCard(false),
            onGood: () => store.answerCurrentCard(true),
            onEasy: () => store.answerCurrentCard(true),
          ),
          const SizedBox(height: 12),
          _FlashcardStatsStrip(
            correct: store.correctAnswers,
            wrong: store.wrongAnswers,
            precision: store.completedCards == 0
                ? deck.retention
                : ((store.correctAnswers / store.completedCards) * 100).round(),
          ),
        ],
      ),
    );
  }
}

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Premium'),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: [
                RefColors.pink.withValues(alpha: .28),
                RefColors.sun.withValues(alpha: .30),
                RefColors.violet.withValues(alpha: .22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: RefColors.glassStrong,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: RefColors.border),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memorizar Premium',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Sin anuncios y con ejercicios inteligentes cuando conectemos IA real.',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 13,
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _PremiumBenefit(
            icon: Icons.quiz_rounded,
            title: 'Quizes inteligentes',
            body:
                'Preguntas y opciones generadas para el contenido que estás memorizando.',
          ),
          const SizedBox(height: 10),
          const _PremiumBenefit(
            icon: Icons.block_rounded,
            title: 'Sin anuncios',
            body: 'La sesión queda limpia y sin interrupciones.',
          ),
          const SizedBox(height: 10),
          const _PremiumBenefit(
            icon: Icons.auto_awesome_rounded,
            title: 'Más ejercicios avanzados',
            body:
                'Variantes de examen para que cada intento se sienta distinto.',
          ),
          const SizedBox(height: 16),
          Cta(
            store.isPremium ? 'Premium activo' : 'Activar cuando esté listo',
            onTap: () {
              store.setPremiumPreview(!store.isPremium);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    store.isPremium
                        ? 'Preview premium activado para probar quizes.'
                        : 'Preview premium desactivado.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Esto es un preview local. El cobro real se conecta luego con StoreKit/RevenueCat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      color: RefColors.glass,
      border: Border.all(color: RefColors.border),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: RefColors.sun.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: RefColors.sun.withValues(alpha: .45)),
            ),
            child: Icon(icon, color: RefColors.sun, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardsTopBar extends StatelessWidget {
  final String title;

  const _FlashcardsTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(exitText: true),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Repaso espaciado',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _FlashcardDeck extends StatelessWidget {
  final MemoryDeckData deck;
  final MemoryCardData card;
  final int index;

  const _FlashcardDeck({
    required this.deck,
    required this.card,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 510,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: -8,
            left: 10,
            right: 10,
            bottom: 8,
            child: Transform.rotate(
              angle: -0.035,
              child: _DeckLayer(opacity: .5),
            ),
          ),
          Positioned.fill(
            top: -4,
            left: 5,
            right: 5,
            bottom: 4,
            child: Transform.rotate(
              angle: 0.018,
              child: _DeckLayer(opacity: .7),
            ),
          ),
          Positioned.fill(
            child: Glass(
              radius: 26,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              gradient: LinearGradient(
                colors: [
                  RefColors.violet.withValues(alpha: .38),
                  RefColors.sun.withValues(alpha: .42),
                  RefColors.violet.withValues(alpha: .28),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FlashcardMeta(deck: deck, index: index),
                  Expanded(child: _FlashcardQuestion(card: card)),
                  _FlashcardHint(card: card),
                  const SizedBox(height: 14),
                  const _FlashcardNavHint(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckLayer extends StatelessWidget {
  final double opacity;

  const _DeckLayer({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RefColors.glassSoft.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: RefColors.border.withValues(alpha: opacity)),
      ),
    );
  }
}

class _FlashcardMeta extends StatelessWidget {
  final MemoryDeckData deck;
  final int index;

  const _FlashcardMeta({required this.deck, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deck.isBible
                    ? 'BIBLIA · ${deck.subtitle}'
                    : deck.subtitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TARJETA ${index + 1} DE ${deck.cards.length}',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: RefColors.glassStrong,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RefColors.border),
          ),
          child: const Icon(Icons.volume_up_outlined, size: 19),
        ),
      ],
    );
  }
}

class _FlashcardQuestion extends StatelessWidget {
  final MemoryCardData card;

  const _FlashcardQuestion({required this.card});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          card.front,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            height: 1.18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
      ),
    );
  }
}

class _FlashcardHint extends StatelessWidget {
  final MemoryCardData card;

  const _FlashcardHint({required this.card});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .30),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: RefColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💡', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                card.back,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardNavHint extends StatelessWidget {
  const _FlashcardNavHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _FlashcardArrow(Icons.arrow_back_rounded),
        Expanded(
          child: Text(
            'Toca para voltear ↻',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _FlashcardArrow(Icons.arrow_forward_rounded),
      ],
    );
  }
}

class _FlashcardArrow extends StatelessWidget {
  final IconData icon;

  const _FlashcardArrow(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        shape: BoxShape.circle,
        border: Border.all(color: RefColors.border),
      ),
      child: Icon(icon, size: 17),
    );
  }
}

class _FlashcardActions extends StatelessWidget {
  final VoidCallback onAgain;
  final VoidCallback onHard;
  final VoidCallback onGood;
  final VoidCallback onEasy;

  const _FlashcardActions({
    required this.onAgain,
    required this.onHard,
    required this.onGood,
    required this.onEasy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FlashcardAction('↻', 'DE NUEVO', RefColors.urgent, onAgain),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FlashcardAction('😬', 'DIFÍCIL', RefColors.sun, onHard),
        ),
        const SizedBox(width: 8),
        Expanded(child: _FlashcardAction('👍', 'BIEN', RefColors.cyan, onGood)),
        const SizedBox(width: 8),
        Expanded(child: _FlashcardAction('✨', 'FÁCIL', RefColors.lime, onEasy)),
      ],
    );
  }
}

class _FlashcardAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _FlashcardAction(this.icon, this.label, this.accent, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        color: accent.withValues(alpha: .10),
        border: Border.all(color: accent.withValues(alpha: .34)),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: icon == '↻' ? 22 : 20)),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardStatsStrip extends StatelessWidget {
  final int correct;
  final int wrong;
  final int precision;

  const _FlashcardStatsStrip({
    required this.correct,
    required this.wrong,
    required this.precision,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      color: RefColors.glassStrong,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FlashStat('$correct', 'CORRECTAS'),
          _FlashStat('$wrong', 'FALLADAS'),
          _FlashStat('$precision%', 'PRECISIÓN'),
        ],
      ),
    );
  }
}

class _FlashStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _FlashStat(this.value, this.label, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

