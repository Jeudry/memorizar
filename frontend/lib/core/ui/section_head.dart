import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Section title row with optional right-aligned action label.
class SectionHead extends StatelessWidget {
  final String title;
  final String? action;

  const SectionHead(this.title, {super.key, this.action});

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
            Text(
              action!,
              style: const TextStyle(color: RefColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
