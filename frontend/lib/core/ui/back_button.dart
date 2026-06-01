import 'package:flutter/material.dart';
import 'main_tab_shell.dart';

import '../router/app_routes.dart';

/// Custom back arrow used by reference screens. Falls back to the home route
/// when there is nothing to pop. Renamed from `BackButton` to avoid the
/// Material widget of the same name.
///
/// Pass [onTap] to override the default pop-or-home behaviour (used e.g. by
/// the exercise screens to jump back to the progress tree instead of the
/// previous step).
class RefBackButton extends StatelessWidget {
  final bool exitText;
  final VoidCallback? onTap;

  const RefBackButton({super.key, this.exitText = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            final shell = MainTabShell.of(context);
            if (shell != null && shell.activeRoute != AppRoutes.home) {
              shell.goToRoute(AppRoutes.home);
            } else if (Navigator.canPop(context)) {
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
