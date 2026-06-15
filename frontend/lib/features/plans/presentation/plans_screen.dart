import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/ref_colors.dart';
import '../../home/presentation/home_screen.dart';
import '../data/reading_plans.dart';
import 'plan_detail_screen.dart';

/// Screen that lists curated multi-day reading plans.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  static const routeName = '/planes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _PlansBackButton(onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Planes de lectura',
                          style: TextStyle(
                            color: RefColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Recorridos guiados día por día. Cada uno carga sus versículos al estudio.',
                      style: TextStyle(color: RefColors.muted, fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final plan in readingPlans) ...[
                    _PlanCard(
                      plan: plan,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlanDetailScreen(planId: plan.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ReadingPlan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RefColors.glass,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: RefColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: RefColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      plan.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            color: RefColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.summary,
                          style: const TextStyle(
                            color: RefColors.muted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: RefColors.glassStrong,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: RefColors.border),
                          ),
                          child: Text(
                            '${plan.totalDays} días',
                            style: const TextStyle(
                              color: RefColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: RefColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlansBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PlansBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RefColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RefColors.border),
          ),
          child: const Icon(Icons.arrow_back, color: RefColors.ink, size: 20),
        ),
      ),
    );
  }
}
