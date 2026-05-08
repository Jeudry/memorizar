import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Pill-shaped tag. Renamed from `Chip` to avoid colliding with the Material
/// widget of the same name.
class RefChip extends StatelessWidget {
  final String text;
  final bool dense;
  final Color? color;
  final Color? textColor;

  const RefChip(
    this.text, {
    super.key,
    this.dense = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color ?? RefColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RefColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
