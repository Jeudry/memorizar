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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: RefColors.glassStrong,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RefBackButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '${AppRoutes.flow}/progress-tree',
                      ModalRoute.withName(AppRoutes.home),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
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
                  child: const RefIconButton(
                    icon: Icons.info_outline_rounded,
                    size: 30,
                    iconSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
