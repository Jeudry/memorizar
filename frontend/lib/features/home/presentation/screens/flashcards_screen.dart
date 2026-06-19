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

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingModel();
  }

  Future<void> _checkExistingModel() async {
    final llm = LocalLlmService.instance;
    final exists = await llm.checkModelExists();
    if (exists && mounted) {
      try {
        await llm.initLlm();
        setState(() {});
      } catch (e) {
        debugPrint('Failed to auto-init LLM: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final llmService = LocalLlmService.instance;

    return ReferencePage(
      showBottomNav: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RefTopBar(title: 'Función Premium'),
            Glass(
              padding: const EdgeInsets.all(20),
              gradient: LinearGradient(
                colors: [
                  RefColors.violet.withValues(alpha: .28),
                  RefColors.pink.withValues(alpha: .20),
                  RefColors.sun.withValues(alpha: .15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: RefColors.glassStrong,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: RefColors.border),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: RefColors.pink, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cuestionario con IA Local',
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              store.isPremium ? '✓ Acceso Desbloqueado' : '🔒 Requiere Premium',
                              style: TextStyle(
                                color: store.isPremium ? RefColors.lime : RefColors.pink,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Esta función despierta una red neuronal artificial directamente dentro de tu teléfono. Analiza tu progreso y crea cuestionarios únicos y distractores inteligentes de forma 100% privada, sin anuncios y sin consumir tus datos de internet.',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Si el usuario no es premium, mostrar el paywall/upsell hermoso
            if (!store.isPremium) ...[
              Glass(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withValues(alpha: 0.2),
                border: Border.all(color: RefColors.border),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: RefColors.sun, size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      'Únete a Memorizar Premium',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Activa la versión de prueba premium para desbloquear la Inteligencia Artificial local y todos los ejercicios de alta fidelidad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RefColors.muted, fontSize: 12, height: 1.35, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Cta(
                      'Activar Prueba Premium Gratis',
                      onTap: () async {
                        final error = await store.activatePremiumTrial();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ??
                                '¡Modo Premium activado! Ahora puedes descargar la IA local.'),
                          ),
                        );
                      },
                    ),
                    if (!store.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Como invitado el premium es solo de prueba local; inicia sesión para conservarlo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: RefColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Si ya es premium, mostrar la opción de descargar el cerebro de IA
              ValueListenableBuilder<String>(
                valueListenable: llmService.statusNotifier,
                builder: (context, status, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: llmService.downloadProgress,
                    builder: (context, progress, _) {
                      final isReady = llmService.isReady || progress >= 1.0;
                      
                      return Glass(
                        padding: const EdgeInsets.all(16),
                        color: RefColors.glassStrong,
                        border: Border.all(color: isReady ? RefColors.lime.withValues(alpha: 0.4) : RefColors.border),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isReady ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
                                  color: isReady ? RefColors.lime : RefColors.pink,
                                  size: 26,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isReady ? 'Cerebro de IA Instalado' : 'Instalar Red Neuronal Local',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        status.isEmpty ? 'Requiere descarga única (~3.0 GB · Gemma 4 QAT)' : status,
                                        style: const TextStyle(color: RefColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isReady) ...[
                              const SizedBox(height: 14),
                              if (_downloading) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white12,
                                    color: RefColors.pink,
                                    minHeight: 6,
                                  ),
                                ),
                              ] else ...[
                                Cta(
                                  'Descargar Motor de IA Offline',
                                  onTap: () async {
                                    setState(() {
                                      _downloading = true;
                                    });
                                    try {
                                      await llmService.downloadModel();
                                    } catch (_) {}
                                    setState(() {
                                      _downloading = false;
                                    });
                                  },
                                ),
                              ],
                            ] else ...[
                              const SizedBox(height: 12),
                              const Text(
                                '¡Felicidades! La IA local está lista y funcionando en la GPU de tu dispositivo. Todos tus cuestionarios se procesarán de forma ultra-rápida y privada.',
                                style: TextStyle(color: RefColors.lime, fontSize: 12, height: 1.3, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 14),
                              Cta(
                                'Continuar al Quiz →',
                                onTap: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              if (!_downloading)
                                GhostButton(
                                  'Limpiar y volver a descargar modelado',
                                  onTap: () async {
                                    setState(() {
                                      _downloading = true;
                                    });
                                    try {
                                      // Eliminar el archivo actual del modelo para forzar la re-descarga de Gemma 4
                                      final path = await llmService.deleteModelFile();
                                      debugPrint('Modelo antiguo limpiado en: $path');
                                      await llmService.downloadModel();
                                    } catch (e) {
                                      debugPrint('Error re-descargando: $e');
                                    } finally {
                                      setState(() {
                                        _downloading = false;
                                      });
                                    }
                                  },
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(color: RefColors.pink),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            
            const SizedBox(height: 16),
            const _PremiumBenefit(
              icon: Icons.quiz_rounded,
              title: 'Cuestionarios Dinámicos',
              body: 'Opciones de respuestas trampa generadas contextualmente para tu mazo.',
            ),
            const SizedBox(height: 10),
            const _PremiumBenefit(
              icon: Icons.offline_bolt_rounded,
              title: 'Funcionamiento 100% Offline',
              body: 'Estudia en el avión, el campo o el sótano. Sin requerir conexión ni wifi.',
            ),
            const SizedBox(height: 10),
            const _PremiumBenefit(
              icon: Icons.shield_rounded,
              title: 'Privacidad Absoluta',
              body: 'Tus datos de estudio nunca salen de tu teléfono. Sin servidores externos.',
            ),
            
            if (store.isPremium) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  store.setPremiumPreview(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preview premium desactivado.')),
                  );
                },
                child: const Text(
                  'Desactivar Preview de Desarrollo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RefColors.pink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
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

  const _FlashStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
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

