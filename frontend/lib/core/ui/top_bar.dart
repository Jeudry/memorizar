import 'package:flutter/material.dart';

import '../app_state.dart';
import '../router/app_routes.dart';
import '../theme/ref_colors.dart';
import 'back_button.dart';
import 'glass.dart';
import 'icon_button.dart';

/// Standard top bar: back button on the left, centred title, notification bell
/// + theme toggle on the right. Used by the reference screens.
class RefTopBar extends StatelessWidget {
  final String title;

  const RefTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const _NotificationBell(),
          const SizedBox(width: 8),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

/// Campana de notificaciones con badge de no-leídas. Refresca el conteo al
/// montarse (cada vez que se entra a una pantalla con top bar) y escucha al
/// [AppStore] para mantener el badge en vivo. Oculta si el usuario no tiene
/// sesión.
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).refreshNotificationCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return const SizedBox.shrink();
    final unread = store.unreadNotifications;
    return GestureDetector(
      onTap: () async {
        final s = store;
        await Navigator.pushNamed(context, AppRoutes.notificaciones);
        if (mounted) s.refreshNotificationCount();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Glass(
            radius: 14,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.notifications_none_rounded, size: 20),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: RefColors.pink,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF120E22), width: 1.5),
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
