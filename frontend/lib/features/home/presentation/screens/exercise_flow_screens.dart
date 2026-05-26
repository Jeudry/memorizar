// AUTO-GENERATED extraction from ui_screens.dart (refactor PR-D).
// Tightly-coupled exercise-flow widgets — kept in this library to
// preserve cross-class private visibility.
part of '../ui_screens.dart';

class _ListenFlowScreen extends StatelessWidget {
  const _ListenFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowTopBar(
            chip: 'Ítem 1/5 · ${AppScope.of(context).activeCard.front}',
          ),
          const _FlowStepHeader(
            step: '1',
            title: '🎧 Escuchar',
            progress: 1,
            difficulty: '🌿 Inter',
          ),
          const _FlowTitle(
            title: 'Escucha y sigue',
            subtitle: 'El texto se resalta al ritmo del audio',
          ),
          const _ListenAudioCard(),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '💡',
            text:
                'Escúchalo al menos 3 veces antes de avanzar. Tu cerebro está formando la pista auditiva.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('🔁 Repetir')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente paso →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/02-lectura-frag',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FragmentedReadingFlowScreen extends StatelessWidget {
  const _FragmentedReadingFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '2',
            title: '👁 Lectura fragmentada',
            progress: 2,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Lee conforme aparece',
            subtitle: 'Activa tu atención · lo verás de a poco',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: RefProgress(.66),
          ),
          const _FragmentedTextCard(),
          const SizedBox(height: 14),
          const _SpeedSelectorCard(),
          const SizedBox(height: 14),
          const _TapPauseCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('← Repetir')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/03-leer-voz',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadAloudFlowScreen extends StatelessWidget {
  const _ReadAloudFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Zen mode'),
          const _FlowStepHeader(
            step: '3',
            title: '🗣 Dilo sin prisas',
            progress: 3,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Léelo en voz alta',
            subtitle: 'Tu voz refuerza la memoria auditiva',
          ),
          const SizedBox(height: 44),
          const _KaraokeLine(fontSize: 29),
          const SizedBox(height: 48),
          const _PulseMic(),
          const SizedBox(height: 42),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 54),
            child: RefProgress(.74),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '• TE ESCUCHO',
              style: TextStyle(
                color: RefColors.pink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('Reiniciar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Finalizar grabación →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/04-escuchar-voz',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListenOwnVoiceFlowScreen extends StatelessWidget {
  const _ListenOwnVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '👂 Tu propia voz'),
          const _FlowStepHeader(
            step: '4',
            title: '🎤 Escúchate',
            progress: 4,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Tu grabación',
            subtitle: 'Oír tu propia voz refuerza la memoria auditiva',
          ),
          const _VoiceQuoteCard(),
          const SizedBox(height: 14),
          const _WaveformCard(kind: _WaveKind.original),
          const SizedBox(height: 14),
          const _WaveformCard(kind: _WaveKind.you),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('🔁 Regrabar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/05-bloques',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlocksFlowScreen extends StatelessWidget {
  const _BlocksFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🧩 Reorganizar'),
          const _FlowStepHeader(
            step: '5',
            title: '🧩 Reorganiza los bloques',
            progress: 5,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Reconstruye el texto',
            subtitle: 'Arrastra los bloques al orden correcto',
          ),
          const _BlocksCounterCard(),
          const SizedBox(height: 14),
          const _BlocksListCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Comprobar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/06-completar-n1',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompleteN1FlowScreen extends StatelessWidget {
  const _CompleteN1FlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '6',
            title: '📝 Completar palabra',
            progress: 6,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Completa el versículo · Nivel 1',
            subtitle: 'Toca una palabra del banco y llena el hueco',
          ),
          const _CompleteStatsCard(),
          const SizedBox(height: 14),
          const _CompleteSentenceCard(),
          const SizedBox(height: 14),
          const _WordBankCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Siguiente →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirstLetterFlowScreen extends StatelessWidget {
  final int level;

  const _FirstLetterFlowScreen({required this.level});

  @override
  Widget build(BuildContext context) {
    final isLevel2 = level == 2;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          _FlowStepHeader(
            step: isLevel2 ? '11' : '7',
            title: '🔤 Primera letra',
            progress: isLevel2 ? 11 : 7,
            difficulty: isLevel2 ? '🌳' : '🌿',
          ),
          _FlowTitle(
            title: 'Escribe la primera letra · Nivel $level',
            subtitle: isLevel2
                ? 'Casi todo está oculto · cronómetro · intentos limitados'
                : 'De cada hueco escribe únicamente su letra inicial',
          ),
          _CompleteStatsCard(
            level2: isLevel2,
            firstValue: isLevel2 ? '1/5' : '1/3',
          ),
          const SizedBox(height: 14),
          _FirstLetterSentence(level: level),
          const SizedBox(height: 14),
          if (!isLevel2) ...[
            const _FlowHintCard(
              icon: '💡',
              text:
                  'No te preocupes por la exactitud: acentos, mayúsculas o minúsculas no cuentan.',
            ),
            const SizedBox(height: 14),
          ],
          const _KeyboardCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    isLevel2
                        ? '${AppRoutes.flow}/12-voz-final'
                        : '${AppRoutes.flow}/08-voz-guiada',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuidedVoiceFlowScreen extends StatelessWidget {
  const _GuidedVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🎤 Recitar completo'),
          const _FlowStepHeader(
            step: '8',
            title: '🎤 Voz con palabras ocultas',
            progress: 8,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Recita el versículo completo',
            subtitle: 'Algunas palabras están ocultas · dilas de memoria',
          ),
          const _CompleteStatsCard(
            firstValue: '3/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS RESTANTES',
          ),
          const SizedBox(height: 14),
          const _VoiceHiddenWordsCard(finalMode: false),
          const SizedBox(height: 14),
          const _ListeningHud(colorMode: _ListeningColorMode.blue),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '💡',
            text:
                'Recita todo literalmente, no solo las ocultas · si pausas más de 5s reiniciamos.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('🔁 Reset')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Terminé →',
                  onTap: () =>
                      Navigator.pushNamed(context, '${AppRoutes.flow}/09-quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizFlowScreen extends StatelessWidget {
  const _QuizFlowScreen();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final options = [
      card,
      ...deck.cards.where((item) => item.id != card.id),
    ].take(4).toList();
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Quiz · 5 preguntas'),
          const _FlowStepHeader(
            step: '9',
            title: '🧠 Entiende el significado',
            progress: 9,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Quiz de comprensión',
            subtitle: '5 preguntas de tipos distintos según el contenido',
          ),
          const _QuizNav(),
          const SizedBox(height: 14),
          _ExerciseQuestionBlock(
            contextLabel: deck.isBible ? card.source : deck.title.toUpperCase(),
            question: deck.isBible
                ? '¿Qué texto pertenece a ${card.front}?'
                : '¿Cuál explicación corresponde a ${card.front}?',
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < options.length; i++) ...[
            _ExerciseOption(
              letter: String.fromCharCode(65 + i),
              title: options[i].back,
              tip: options[i].source,
              selected: i == 0,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 140, child: GhostButton('💡 Explicar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Confirmar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/10-completar-n2',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompleteN2FlowScreen extends StatelessWidget {
  const _CompleteN2FlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '10',
            title: '📝 Completar palabra',
            progress: 10,
            difficulty: '🌳',
          ),
          const _FlowTitle(
            title: 'Completa el versículo · Nivel 2',
            subtitle: 'Más huecos · cronómetro · intentos limitados',
          ),
          const _CompleteStatsCard(
            level2: true,
            firstValue: '1/5',
            secondValue: '2/3',
          ),
          const SizedBox(height: 14),
          const _CompleteSentenceCard(level2: true),
          const SizedBox(height: 14),
          const _WordBankCard(level2: true),
          const SizedBox(height: 14),
          const _WarningCard(
            text:
                'Nivel 2: si fallas 3 veces o se acaba el tiempo, vuelves al paso anterior.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('↩ Vaciar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Comprobar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/11-primera-letra-n2',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalVoiceFlowScreen extends StatelessWidget {
  const _FinalVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🏆 EXAMEN FINAL'),
          const _FlowStepHeader(
            step: '12',
            title: '🎤 Recitación final',
            progress: 12,
            difficulty: '🌳',
          ),
          const _FlowTitle(
            title: 'Recita el versículo completo · Examen',
            subtitle: 'Sin ayudas · todas las palabras están ocultas',
          ),
          const _CompleteStatsCard(
            level2: true,
            firstValue: '0/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS RESTANTES',
            timeValue: '00:30',
          ),
          const SizedBox(height: 14),
          const _VoiceHiddenWordsCard(finalMode: true),
          const SizedBox(height: 14),
          const _ListeningHud(colorMode: _ListeningColorMode.pink),
          const SizedBox(height: 14),
          const _WarningCard(
            text:
                'Examen final: recita todo de memoria sin parar más de 5s. Si fallas 2 veces vuelves al paso anterior.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('🔁 Reset')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Terminé →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniReviewFlowScreen extends StatelessWidget {
  const _MiniReviewFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Mini-repaso'),
          const _MiniReviewHero(),
          const SizedBox(height: 14),
          const _MiniReviewTabs(),
          const SizedBox(height: 16),
          const _FlowTitle(
            title: '🎯 Asocia cada referencia con su texto',
            subtitle:
                'Toca una referencia y luego su texto · arrastrar también funciona',
          ),
          const _MiniReviewCounter(),
          const SizedBox(height: 14),
          const _PairMatchCard(),
          const SizedBox(height: 18),
          const _FlowHintCard(
            icon: '💡',
            text: 'Toca una referencia y luego su texto correspondiente',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 96, child: GhostButton('Saltar')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Siguiente ejercicio →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalReviewFlowScreen extends StatelessWidget {
  const _FinalReviewFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'FIN DE SESIÓN'),
          const _FinalSuccessHero(),
          const SizedBox(height: 16),
          const _FinalScoreCard(),
          const SizedBox(height: 14),
          const _ShareAchievementCard(),
          const SizedBox(height: 14),
          const _FinalVersesCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 96, child: GhostButton('Repetir')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Volver a inicio →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowTopBar extends StatelessWidget {
  final String chip;

  const _FlowTopBar({required this.chip});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dynamicChip = chip.contains('Ítem') || chip.contains('Item')
        ? 'Ítem ${store.currentCardIndex + 1}/${store.activeDeck.cards.length} · ${store.activeCard.front}'
        : chip;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          RefBackButton(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '${AppRoutes.flow}/progress-tree',
                ModalRoute.withName(AppRoutes.home),
              );
            },
          ),
          Expanded(child: Center(child: RefChip(dynamicChip, dense: true))),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _FlowStepHeader extends StatelessWidget {
  final String step;
  final String title;
  final int progress;
  final int totalSteps;
  final String? difficulty;

  const _FlowStepHeader({
    required this.step,
    required this.title,
    required this.progress,
    this.totalSteps = 12,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        color: RefColors.glassStrong,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RefBackButton(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '${AppRoutes.flow}/progress-tree',
                      ModalRoute.withName(AppRoutes.home),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  'PASO $step/$totalSteps',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${store.activeDeck.cards.length} items · paso $step de $totalSteps · ${store.activeDeck.title}',
                      ),
                    ),
                  ),
                  child: const RefIconButton(icon: Icons.info_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (var i = 1; i <= totalSteps; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i < progress
                              ? RefColors.lime
                              : i == progress
                              ? RefColors.pink
                              : RefColors.glassSoft,
                        ),
                      ),
                    ),
                    if (i < totalSteps) const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FlowTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

