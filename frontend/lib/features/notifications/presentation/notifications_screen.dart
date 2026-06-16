import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Centro de notificaciones (campanita). Lista las notificaciones in-app
/// persistidas del usuario — likes, follows, comentarios, mazos compartidos,
/// solicitudes de amistad — vía GET /v1/notifications. Al abrir marca todas
/// como leídas para limpiar el badge.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() => _loading = true);
    try {
      final result = await store.api.listNotifications();
      if (!mounted) return;
      setState(() => _items = result.items);
      // Marcar todas como leídas al abrir: limpia el badge global pero
      // conservamos el snapshot (con su flag read original) para resaltar las
      // que llegaron sin leer en esta visita.
      if (result.unread > 0) {
        await store.api.markNotificationsRead();
        store.setUnreadNotifications(0);
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Mapea el deeplink de la notificación a una ruta interna conocida.
  void _openDeeplink(Map<String, dynamic> data) {
    final deeplink = (data['deeplink'] as String?) ?? '';
    final route = switch (deeplink) {
      'memorizar://comunidad' => AppRoutes.comunidad,
      'memorizar://amigos' => AppRoutes.amigos,
      _ => null,
    };
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = _items ?? const [];
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.comunidad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Notificaciones'),
          if (!store.isLoggedIn)
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: RefColors.cyan, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Inicia sesión para ver tus notificaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RefColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Cta(
                    'Iniciar sesión',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                ],
              ),
            )
          else if (_loading && _items == null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (items.isEmpty) ...[
            Glass(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: const [
                  Icon(Icons.notifications_none_rounded,
                      color: RefColors.cyan, size: 42),
                  SizedBox(height: 10),
                  Text(
                    'Sin notificaciones todavía',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cuando alguien le dé me gusta a tus mazos, te siga o te '
                    'comparta algo, aparecerá aquí.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: RefColors.muted, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ] else ...[
            for (final n in items)
              _NotificationRow(
                notification: n,
                onTap: () => _openDeeplink(
                    (n['data'] as Map?)?.cast<String, dynamic>() ?? const {}),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationRow({required this.notification, required this.onTap});

  static const Map<String, (IconData, Color)> _styleByType = {
    'deck_liked': (Icons.favorite_rounded, RefColors.pink),
    'followed': (Icons.person_add_rounded, RefColors.cyan),
    'friend_requested': (Icons.person_outline_rounded, RefColors.cyan),
    'friend_accepted': (Icons.how_to_reg_rounded, RefColors.lime),
    'deck_shared': (Icons.card_giftcard_rounded, RefColors.lime),
    'reaction_added': (Icons.emoji_emotions_rounded, RefColors.sun),
    'comment_added': (Icons.mode_comment_rounded, RefColors.cyan),
  };

  @override
  Widget build(BuildContext context) {
    final type = (notification['type'] as String?) ?? '';
    final title = (notification['title'] as String?) ?? '';
    final body = (notification['body'] as String?) ?? '';
    final read = (notification['read'] as bool?) ?? true;
    final created = DateTime.tryParse(
            (notification['createdAt'] as String?) ?? '')
        ?.toLocal();
    final (icon, color) =
        _styleByType[type] ?? (Icons.notifications_rounded, RefColors.cyan);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read
              ? HtmlRefColors.glassSoft
              : color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: read
                ? HtmlRefColors.glassBorder
                : color.withValues(alpha: .35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: read ? FontWeight.w700 : FontWeight.w900,
                      color: RefColors.ink,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RefColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (created != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(created),
                      style: const TextStyle(
                        fontSize: 10,
                        color: RefColors.dim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!read)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tiempo relativo simple en español, basado en la hora local del dispositivo.
  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} ${diff.inHours == 1 ? "hora" : "horas"}';
    }
    if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} ${diff.inDays == 1 ? "día" : "días"}';
    }
    return '${when.day}/${when.month}/${when.year}';
  }
}
