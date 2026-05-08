import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Secondary button — glass surface, no gradient. Used alongside [Cta].
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const GhostButton(this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: RefColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RefColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
