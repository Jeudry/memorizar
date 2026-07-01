import 'package:flutter/material.dart';
import 'main_tab_shell.dart';

import '../router/app_routes.dart';
import '../theme/ref_colors.dart';
import 'glass.dart';

/// Floating bottom navigation pill used by the home-level screens. Renamed
/// from `BottomNav` to avoid colliding with the Material `BottomNavigationBar`
/// concept and keep the `Ref*` family consistent.
class RefBottomNav extends StatelessWidget {
  final String active;

  const RefBottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      color: RefColors.bg.withValues(alpha: .6),
      child: Row(
        children: [
          RefBottomItem(Icons.home_outlined, 'Inicio', AppRoutes.home, active: active),
          RefBottomItem(Icons.rectangle_outlined, 'Mazos', AppRoutes.repasar, active: active),
          RefBottomItem(Icons.people_outline, 'Amigos', AppRoutes.amigos, active: active),
          RefBottomItem(Icons.public, 'Comunidad', AppRoutes.comunidad, active: active),
          RefBottomItem(Icons.pie_chart_outline, 'Stats', AppRoutes.stats, active: active),
        ],
      ),
    );
  }
}

class RefBottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String active;

  const RefBottomItem(this.icon, this.label, this.route, {super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final isActive = active == route;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isActive) {
            final shell = MainTabShell.of(context);
            if (shell != null) {
              shell.goToRoute(route);
            } else {
              final routesOrder = [
                AppRoutes.home,
                AppRoutes.repasar,
                AppRoutes.amigos,
                AppRoutes.comunidad,
                AppRoutes.stats,
              ];
              final currentIndex = routesOrder.indexOf(active);
              final targetIndex = routesOrder.indexOf(route);
              final beginOffset = targetIndex > currentIndex
                  ? const Offset(1.0, 0.0)
                  : const Offset(-1.0, 0.0);
              Navigator.pushReplacement(
                context,
                AppRoutes.slideRoute(route, begin: beginOffset),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: isActive
              ? BoxDecoration(
                  gradient: RefColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: RefColors.pink.withValues(alpha: .4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : RefColors.muted,
              ),
              const SizedBox(height: 2),
              // Una sola línea siempre: si no cabe, se reduce un poco (no se
              // parte en dos, que descuadraba la altura de la barra).
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : RefColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
