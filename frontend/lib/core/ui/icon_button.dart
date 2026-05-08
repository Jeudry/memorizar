import 'package:flutter/material.dart';

import 'glass.dart';

/// Square glass icon button (40x40). Renamed from `IconButton` to avoid
/// shadowing the Material widget of the same name.
class RefIconButton extends StatelessWidget {
  final IconData icon;

  const RefIconButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: EdgeInsets.zero,
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20)),
    );
  }
}
