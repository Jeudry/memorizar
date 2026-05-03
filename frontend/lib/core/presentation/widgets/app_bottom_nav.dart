import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../router/app_routes.dart';
import 'glass.dart';

class AppBottomNav extends StatelessWidget {
  final String active;

  const AppBottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      color: RefColors.bg.withValues(alpha: .6),
      child: Row(
        children: [
          _BottomItem(Icons.home_outlined, 'Inicio', AppRoutes.home, active),
          _BottomItem(Icons.rectangle_outlined, 'Mazos', AppRoutes.repasar, active),
          _BottomItem(Icons.people_outline, 'Amigos', AppRoutes.amigos, active),
          _BottomItem(Icons.public, 'Comunidad', AppRoutes.comunidad, active),
          _BottomItem(Icons.pie_chart_outline, 'Stats', AppRoutes.stats, active),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String activeRoute;

  const _BottomItem(this.icon, this.label, this.route, this.activeRoute);

  @override
  Widget build(BuildContext context) {
    final isActive = activeRoute == route;
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
