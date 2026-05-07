import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Primary call-to-action button (full width, gradient).
class Cta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;

  const Cta(this.label, {super.key, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onTap == null;
    return Opacity(
      opacity: isDisabled ? .45 : 1,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            gradient: isDisabled ? null : RefColors.primary,
            color: isDisabled ? RefColors.glass : null,
            borderRadius: BorderRadius.circular(18),
            border: isDisabled ? Border.all(color: RefColors.border) : null,
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: RefColors.pink.withValues(alpha: .4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
