import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';
import 'package:memorizar/features/review/data/models/review_rating.dart';
import 'package:memorizar/features/review/presentation/providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _reveal(ReviewSessionNotifier notifier) {
    notifier.reveal();
    _flipController.forward();
  }

  void _rate(ReviewSessionNotifier notifier, ReviewRating rating) {
    _slideController.reverse().then((_) {
      notifier.rate(rating);
      _flipController.reset();
      _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(reviewSessionProvider(widget.deckId));
    final notifier = ref.read(reviewSessionProvider(widget.deckId).notifier);
    final deck = ref.watch(deckByIdProvider(widget.deckId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (session.isFinished) {
      return _FinishedScreen(
        completed: session.completed.length,
        deckName: deck?.name ?? '',
        onBack: () => context.pop(),
      );
    }

    final item = session.currentItem!;
    final accent = deck != null
        ? AppColors.deckAccents[deck.accentColorIndex % AppColors.deckAccents.length]
        : AppColors.indigo;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(deck?.name ?? 'Repaso'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${session.currentIndex + 1} / ${session.queue.length}',
                style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: session.progress,
            backgroundColor: cs.outline,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Flip card
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GestureDetector(
                    onTap: session.isRevealed ? null : () => _reveal(notifier),
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final isBack = _flipAnimation.value > 0.5;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(isBack
                                ? math.pi * (1 - _flipAnimation.value)
                                : math.pi * _flipAnimation.value),
                          child: isBack
                              ? _CardBack(item: item, accent: accent, theme: theme, cs: cs)
                              : _CardFront(item: item, accent: accent, theme: theme, cs: cs),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Rating buttons or reveal prompt
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: session.isRevealed
                    ? _RatingButtons(onRate: (r) => _rate(notifier, r))
                    : _RevealButton(onReveal: () => _reveal(notifier), accent: accent),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.item, required this.accent, required this.theme, required this.cs});
  final Item item;
  final Color accent;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'FRENTE',
                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              item.front,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (item.book != null) ...[
              const SizedBox(height: 20),
              Text(
                '${item.book} ${item.chapter}:${item.verse}',
                style: theme.textTheme.bodySmall?.copyWith(color: accent),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 6),
                Text(
                  'Toca para revelar',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.item, required this.accent, required this.theme, required this.cs});
  final Item item;
  final Color accent;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateX(math.pi),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'RESPUESTA',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                item.front,
                style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Text(
                item.back,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.onReveal, required this.accent});
  final VoidCallback onReveal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onReveal,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Mostrar respuesta'),
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  const _RatingButtons({required this.onRate});
  final void Function(ReviewRating) onRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo te fue?',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: ReviewRating.values.map((r) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: r != ReviewRating.easy ? 8 : 0),
              child: _RatingButton(rating: r, onTap: () => onRate(r)),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _RatingButton extends StatefulWidget {
  const _RatingButton({required this.rating, required this.onTap});
  final ReviewRating rating;
  final VoidCallback onTap;

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.rating) {
        ReviewRating.again => AppColors.ratingAgain,
        ReviewRating.hard => AppColors.ratingHard,
        ReviewRating.good => AppColors.ratingGood,
        ReviewRating.easy => AppColors.ratingEasy,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _color.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.rating.label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishedScreen extends StatefulWidget {
  const _FinishedScreen({required this.completed, required this.deckName, required this.onBack});
  final int completed;
  final String deckName;
  final VoidCallback onBack;

  @override
  State<_FinishedScreen> createState() => _FinishedScreenState();
}

class _FinishedScreenState extends State<_FinishedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final List<AnimationController> _particleCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _particleCtrl = List.generate(
      6,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000 + i * 200),
      ),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scaleCtrl.forward();
        _fadeCtrl.forward();
        for (final c in _particleCtrl) {
          Future.delayed(Duration(milliseconds: _particleCtrl.indexOf(c) * 150), () {
            if (mounted) c.repeat(reverse: true);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    for (final c in _particleCtrl) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final emojis = ['🎉', '⭐', '✨', '🌟', '💫', '🎊'];
    final offsets = [
      const Offset(-120, -80),
      const Offset(120, -100),
      const Offset(-100, 60),
      const Offset(130, 50),
      const Offset(-60, -140),
      const Offset(80, -130),
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated emoji with particles
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Floating particles
                          ...List.generate(6, (i) {
                            return AnimatedBuilder(
                              animation: _particleCtrl[i],
                              builder: (context, child) {
                                final t = _particleCtrl[i].value;
                                return Transform.translate(
                                  offset: offsets[i] * 0.3 +
                                      Offset(0, -20 * math.sin(t * math.pi)),
                                  child: Opacity(
                                    opacity: 0.4 + 0.6 * t,
                                    child: Text(emojis[i],
                                        style: TextStyle(fontSize: 16 + 8 * t)),
                                  ),
                                );
                              },
                            );
                          }),
                          // Main emoji
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.indigo.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🎉', style: TextStyle(fontSize: 52)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Sesión completada!',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Repasaste ${widget.completed} tarjetas de ${widget.deckName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 Racha mantenida',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: widget.onBack,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Volver al deck'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
