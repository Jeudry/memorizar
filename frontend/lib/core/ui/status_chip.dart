import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Small pill used for status / metadata text (e.g. retention %, "PREMIUM").
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;
  final Color textColor;

  const StatusChip(
    this.text, {
    super.key,
    this.color = HtmlRefColors.glassStrong,
    this.borderColor = HtmlRefColors.glassBorder,
    this.textColor = RefColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
