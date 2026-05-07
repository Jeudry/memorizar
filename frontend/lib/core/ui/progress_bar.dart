import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Thin gradient progress bar. Renamed from `Progress` to avoid the very
/// generic name colliding with future widgets.
class RefProgress extends StatelessWidget {
  final double value;
  final Gradient gradient;

  const RefProgress(
    this.value, {
    super.key,
    this.gradient = RefColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: RefColors.glassSoft,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
      ),
    );
  }
}
