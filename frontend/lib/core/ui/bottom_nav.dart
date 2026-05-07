import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      color: RefColors.bg.withValues(alpha: .6),
      child: Row(
        children: const [
          RefBottomItem(Icons.home_outlined, 'Inicio', AppRoutes.home),
          RefBottomItem(Icons.rectangle_outlined, 'Mazos', AppRoutes.repasar),
          RefBottomItem(Icons.people_outline, 'Amigos', AppRoutes.amigos),
          RefBottomItem(Icons.public, 'Comunidad', AppRoutes.comunidad),
          RefBottomItem(Icons.pie_chart_outline, 'Stats', AppRoutes.stats),
        ],
      ),
    );
  }
}

class RefBottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const RefBottomItem(this.icon, this.label, this.route, {super.key});

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<RefBottomNav>();
    final isActive = parent?.active == route;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) Navigator.pushReplacementNamed(context, route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : RefColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
