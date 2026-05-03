import 'package:flutter/material.dart';
import '../../../../../core/app_state.dart';
import '../../../../../core/presentation/widgets/back_button.dart';
import '../../../../../core/presentation/widgets/glass.dart';
import '../../../../../core/presentation/widgets/glass_icon_button.dart';
import '../../../../../core/presentation/widgets/status_chip.dart';
import '../../../../../core/theme.dart';

class FlowTopBar extends StatelessWidget {
  final String chip;

  const FlowTopBar({super.key, required this.chip});

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
          const CustomBackButton(),
          Expanded(child: Center(child: StatusChip(dynamicChip, dense: true))),
          const GlassIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class FlowStepHeader extends StatelessWidget {
  final String step;
  final String title;
  final int progress;
  final String? difficulty;

  const FlowStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.progress,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
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
                const CustomBackButton(),
                const SizedBox(width: 10),
                StatusChip('Paso $step', color: RefColors.pink, textColor: Colors.white),
                const Spacer(),
                if (difficulty != null) StatusChip(difficulty!),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _ProgressBar(progress: progress),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: RefColors.bg.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(10, (index) {
          final isActive = index < progress;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                gradient: isActive ? RefColors.primary : null,
                color: isActive ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}
