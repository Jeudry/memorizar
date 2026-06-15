// Cabecera de paso del flujo de ejercicios. El resto de pantallas mock de
// este archivo (extracción original del refactor PR-D) eran código muerto
// tras el early-return de ExerciseFlowScreen → _RealExerciseFlowScreen y se
// eliminaron. Solo _FlowStepHeader lo usa el motor real.
part of '../ui_screens.dart';

class _FlowStepHeader extends StatelessWidget {
  final String step;
  final String title;
  final int progress;
  final int totalSteps;

  const _FlowStepHeader({
    required this.step,
    required this.title,
    required this.progress,
    this.totalSteps = 12,
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
