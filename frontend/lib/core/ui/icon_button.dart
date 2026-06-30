import 'package:flutter/material.dart';

import 'glass.dart';

/// Square glass icon button (40x40). Renamed from `IconButton` to avoid
/// shadowing the Material widget of the same name.
class RefIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  const RefIconButton({
    super.key,
    required this.icon,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: size < 36 ? 11 : 14,
      padding: EdgeInsets.zero,
      child: SizedBox(width: size, height: size, child: Icon(icon, size: iconSize)),
    );
  }
}
