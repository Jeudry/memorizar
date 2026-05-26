// Generado del refactor de ui_screens.dart.
// EjerciciosScreen + helpers de top bar y session plan.
part of '../ui_screens.dart';

class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final progress = deck.cards.isEmpty
        ? 0.0
        : ((store.currentCardIndex + 1) / deck.cards.length).clamp(.08, 1.0);
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ExerciseTimerTopBar(),
          _SessionEntryMeta(
            current: store.currentCardIndex + 1,
            total: deck.cards.length,
          ),
          RefProgress(progress),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              colors: [
                RefColors.violet.withValues(alpha: .24),
                RefColors.sun.withValues(alpha: .16),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.title,
                  style: const TextStyle(
                    color: RefColors.sun,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  card.front,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  card.back,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RefColors.ink,
                    fontSize: 15,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '🧭',
            text:
                'Primero vas a leer y escuchar el contenido. Después vienen reconstrucción, completar palabras, iniciales y repaso final.',
          ),
          const SizedBox(height: 14),
          _SessionPlanCard(total: deck.cards.length),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Quiz premium',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Cta(
                  'Empezar estudio →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/01-escuchar',
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

class _ExerciseTimerTopBar extends StatelessWidget {
  const _ExerciseTimerTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RefColors.glassStrong,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: RefColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: RefColors.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      '02:14',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _SessionEntryMeta extends StatelessWidget {
  final int current;
  final int total;

  const _SessionEntryMeta({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == 0 ? 'SESIÓN SIN TARJETAS' : 'Ítem $current de $total',
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const _ExerciseXpChip(),
        ],
      ),
    );
  }
}

class _SessionPlanCard extends StatelessWidget {
  final int total;

  const _SessionPlanCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      color: RefColors.glassSoft,
      child: Column(
        children: [
          _PlanRow('1', 'Absorber', 'Lee y escucha el contenido real'),
          const SizedBox(height: 8),
          _PlanRow('2', 'Reconstruir', 'Ordena bloques y completa palabras'),
          const SizedBox(height: 8),
          _PlanRow('3', 'Verificar', 'Quiz y mini-review al final'),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String n;
  final String title;
  final String subtitle;

  const _PlanRow(this.n, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: RefColors.glassStrong,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RefColors.border),
          ),
          child: Text(
            n,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: RefColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseXpChip extends StatelessWidget {
  const _ExerciseXpChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RefColors.border),
      ),
      child: const Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: 12)),
          SizedBox(width: 7),
          Text(
            '+120',
            style: TextStyle(
              color: RefColors.sun,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            ' XP',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ExerciseQuestionBlock extends StatelessWidget {
  final String contextLabel;
  final String question;

  const _ExerciseQuestionBlock({
    this.contextLabel = 'ANATOMÍA · SISTEMA MUSCULAR',
    this.question =
        '¿Cuál de los siguientes músculos flexiona el antebrazo sobre el brazo?',
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contextLabel,
            style: const TextStyle(
              color: RefColors.sun,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              height: 1.28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOption extends StatelessWidget {
  final String letter;
  final String title;
  final String? tip;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  const _ExerciseOption({
    required this.letter,
    required this.title,
    this.tip,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : wrong
        ? RefColors.urgent
        : selected
        ? RefColors.cyan
        : RefColors.border;
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(16),
        color: (correct || wrong || selected)
            ? accent.withValues(alpha: .14)
            : RefColors.glass,
        border: Border.all(color: accent.withValues(alpha: .5)),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (correct || wrong || selected)
                    ? accent
                    : RefColors.glassSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (correct || wrong || selected)
                      ? Colors.transparent
                      : RefColors.border,
                ),
              ),
              child: Center(
                child: correct || wrong
                    ? Icon(
                        correct ? Icons.check_rounded : Icons.close_rounded,
                        color: correct ? const Color(0xFF153A18) : Colors.white,
                        size: 18,
                      )
                    : Text(
                        letter,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF003A4A)
                              : RefColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

