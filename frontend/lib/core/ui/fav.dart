import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Square avatar tile with an initial / emoji and optional online dot.
class Fav extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final double size;
  final bool online;

  const Fav(
    this.text, {
    super.key,
    this.gradient = RefColors.primary,
    this.size = 38,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(size * .32),
            border: Border.all(color: RefColors.border),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * .36,
              ),
            ),
          ),
        ),
        if (online)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: RefColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: RefColors.bg, width: 2),
                boxShadow: const [
                  BoxShadow(color: RefColors.lime, blurRadius: 6),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
