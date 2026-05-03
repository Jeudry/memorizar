import 'package:flutter/material.dart';
import '../../../../../core/presentation/widgets/glass.dart';
import '../../../../../core/theme.dart';

class BlocksCounterCard extends StatelessWidget {
  final int total;
  final int correct;

  const BlocksCounterCard({super.key, required this.total, required this.correct});

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _Stat(
            label: 'BLOQUES',
            value: '$total',
            icon: Icons.extension_rounded,
          ),
          Container(
            height: 30,
            width: 1,
            color: RefColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _Stat(
            label: 'ORDENADOS',
            value: '$correct',
            icon: Icons.check_circle_rounded,
            color: RefColors.pink,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? RefColors.muted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: RefColors.dim,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
