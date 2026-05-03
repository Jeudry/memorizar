import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../router/app_routes.dart';
import 'app_aurora_background.dart';
import 'app_bottom_nav.dart';

class ReferencePage extends StatelessWidget {
  final Widget child;
  final bool showBottomNav;
  final String active;
  final bool scrollable;

  const ReferencePage({
    super.key,
    required this.child,
    this.showBottomNav = true,
    this.active = AppRoutes.home,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: scrollable
                ? SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, showBottomNav ? 118 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [child],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, showBottomNav ? 118 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Expanded(child: child)],
                    ),
                  ),
          ),
          if (showBottomNav)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: AppBottomNav(active: active),
            ),
        ],
      ),
    );
  }
}

