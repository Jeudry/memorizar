import 'package:flutter/material.dart';

import '../router/app_routes.dart';

/// Custom back arrow used by reference screens. Falls back to the home route
/// when there is nothing to pop. Renamed from `BackButton` to avoid the
/// Material widget of the same name.
class RefBackButton extends StatelessWidget {
  final bool exitText;

  const RefBackButton({super.key, this.exitText = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left_rounded, size: 24),
          if (exitText)
            const Text('Salir', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
