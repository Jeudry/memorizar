import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Section title row with optional right-aligned action label.
class SectionHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHead(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                action!,
                style: TextStyle(
                  color: onAction != null ? RefColors.cyan : RefColors.muted,
                  fontSize: 12,
                  fontWeight: onAction != null ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
