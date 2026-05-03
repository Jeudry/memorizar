import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';

class VerseBlock extends StatelessWidget {
  final String index;
  final String text;
  final bool correct;
  final bool wrong;
  final bool moving;

  const VerseBlock(
    this.index,
    this.text, {
    super.key,
    this.correct = false,
    this.wrong = false,
    this.moving = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = RefColors.glass;
    Color borderColor = RefColors.border;
    Color textColor = Colors.white;

    if (moving) {
      borderColor = RefColors.pink;
    } else if (correct) {
      bgColor = const Color(0xFF1B4332).withValues(alpha: 0.6);
      borderColor = const Color(0xFF2D6A4F).withValues(alpha: 0.8);
      textColor = const Color(0xFFD8F3DC);
    } else if (wrong) {
      bgColor = const Color(0xFF431B1B).withValues(alpha: 0.6);
      borderColor = const Color(0xFF6A2D2D).withValues(alpha: 0.8);
      textColor = const Color(0xFFF3D8D8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: moving ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: RefColors.glassStrong,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                index,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: moving ? RefColors.pink : RefColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Icon(
            moving ? Icons.drag_indicator : Icons.unfold_more,
            size: 18,
            color: moving ? RefColors.pink : RefColors.dim,
          ),
        ],
      ),
    );
  }
}
