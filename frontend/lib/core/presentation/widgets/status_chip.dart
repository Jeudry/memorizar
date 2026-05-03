import 'package:flutter/material.dart';
import '../../theme.dart';

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final bool dense;

  const StatusChip(
    this.text, {
    super.key,
    this.color = HtmlRefColors.glassStrong,
    this.borderColor = HtmlRefColors.glassBorder,
    this.textColor = RefColors.ink,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(dense ? 7 : 10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: dense ? 9 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
