import 'package:flutter/material.dart';
import 'glass.dart';

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const GlassIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 14,
        padding: EdgeInsets.zero,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20)),
      ),
    );
  }
}
