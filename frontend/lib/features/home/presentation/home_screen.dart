import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/api/models.dart';
import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme.dart';
import 'glyph_icon.dart';
import '../../../core/ui/main_tab_shell.dart';
import 'ui_screens.dart';
import '../../cooperativo/data/coop_service.dart';

class HomeScreen extends StatelessWidget {
  final HomeBackgroundVariant backgroundVariant;

  const HomeScreen({
    super.key,
    this.backgroundVariant = HomeBackgroundVariant.actualSuave,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final isInsideShell = MainTabShell.of(context) != null;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header
          const _AppHeader(),
          const SizedBox(height: 18),

          // Memorizar algo nuevo
          const _SectionHeader(title: 'Memorizar algo nuevo'),
          const _MemorizarGrid(),
          const SizedBox(height: 12),
          const _CoopBar(),
          const SizedBox(height: 18),

          // De la comunidad
          _SectionHeader(
            title: store.hasDecks ? 'Tus mazos' : 'Tu biblioteca',
            trailing: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/comunidad'),
              child: const Text(
                'Ver más',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const _CommunitySlider(),
          const SizedBox(height: 18),

          // Comunidad
          _SectionHeader(
            title: 'Comunidad',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/comunidad'),
              child: const Text(
                'Explorar',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const _HomeCommunitySlider(),
          const SizedBox(height: 18),

          // Amigos
          _SectionHeader(
            title: 'Amigos',
            trailing: TextButton(
              onPressed: () {
                if (store.isLoggedIn) {
                  AmigosScreen.showAddFriendModal(context);
                } else {
                  Navigator.pushNamed(context, '/amigos');
                }
              },
              child: const Text(
                '+ Invitar',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const _FriendsSlider(),
          const SizedBox(height: 18),

          // Logros
          _SectionHeader(
            title: 'Actividad',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/stats'),
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          _ActivityFeed(),
          const SizedBox(height: 180), // Space for bottom nav
        ],
      ),
    );

    if (isInsideShell) {
      return content;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Aurora Background
          AppAuroraBackground(variant: backgroundVariant),

          // Main Content
          SafeArea(
            child: content,
          ),

          // Bottom Nav
          const Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: _BottomNav(),
          ),
        ],
      ),
    );
  }
}

enum HomeBackgroundVariant {
  current,
  nocturnoMate,
  vinoAhumado,
  tintaProfunda,
  brasaSuave,
  carbonAmbar,
  ciruelaTostada,
  petroleoDorado,
  naranjaNocturno,
  actualSuave,
}

class AppAuroraBackground extends StatelessWidget {
  final HomeBackgroundVariant variant;

  const AppAuroraBackground({
    super.key,
    this.variant = HomeBackgroundVariant.actualSuave,
  });

  @override
  Widget build(BuildContext context) {
    final preset = _AuroraPreset.forVariant(variant);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: preset.baseGradient),
          ),
        ),
        // Background Stars/Dots
        Positioned.fill(
          child: CustomPaint(painter: _StarsPainter(preset.starAlpha)),
        ),
        Positioned(
          top: -50,
          left: -100,
          child: _AuroraCircle(color: preset.topGlow, size: preset.topSize),
        ),
        Positioned(
          top: 150,
          right: -150,
          child: _AuroraCircle(color: preset.sideGlow, size: preset.sideSize),
        ),
        Positioned(
          bottom: -250,
          left: 0,
          child: _AuroraCircle(
            color: preset.bottomGlow,
            size: preset.bottomSize,
          ),
        ),
      ],
    );
  }
}

class _AuroraPreset {
  final LinearGradient baseGradient;
  final Color topGlow;
  final Color sideGlow;
  final Color bottomGlow;
  final double topSize;
  final double sideSize;
  final double bottomSize;
  final double starAlpha;

  const _AuroraPreset({
    required this.baseGradient,
    required this.topGlow,
    required this.sideGlow,
    required this.bottomGlow,
    required this.topSize,
    required this.sideSize,
    required this.bottomSize,
    required this.starAlpha,
  });

  factory _AuroraPreset.forVariant(HomeBackgroundVariant variant) {
    switch (variant) {
      case HomeBackgroundVariant.nocturnoMate:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF110827), Color(0xFF170B2F), Color(0xFF101E34)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          topGlow: Color(0x267C3AFF),
          sideGlow: Color(0x1FFF3EA5),
          bottomGlow: Color(0x1A00D4FF),
          topSize: 520,
          sideSize: 560,
          bottomSize: 760,
          starAlpha: .05,
        );
      case HomeBackgroundVariant.vinoAhumado:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF170827), Color(0xFF24102B), Color(0xFF122238)],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
          topGlow: Color(0x2EFF3EA5),
          sideGlow: Color(0x2BFFB400),
          bottomGlow: Color(0x1800D4FF),
          topSize: 470,
          sideSize: 520,
          bottomSize: 700,
          starAlpha: .04,
        );
      case HomeBackgroundVariant.tintaProfunda:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF0D0622), Color(0xFF12092B), Color(0xFF09263A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
          topGlow: Color(0x1BFF3EA5),
          sideGlow: Color(0x1D7C3AFF),
          bottomGlow: Color(0x2400D4FF),
          topSize: 420,
          sideSize: 520,
          bottomSize: 680,
          starAlpha: .035,
        );
      case HomeBackgroundVariant.brasaSuave:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF150727), Color(0xFF211028), Color(0xFF142138)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          topGlow: Color(0x24FF3EA5),
          sideGlow: Color(0x36FF8A1F),
          bottomGlow: Color(0x1F00D4FF),
          topSize: 460,
          sideSize: 580,
          bottomSize: 720,
          starAlpha: .04,
        );
      case HomeBackgroundVariant.carbonAmbar:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF0E081B), Color(0xFF18101E), Color(0xFF112133)],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
          topGlow: Color(0x1C7C3AFF),
          sideGlow: Color(0x30FFB400),
          bottomGlow: Color(0x1700D4FF),
          topSize: 420,
          sideSize: 540,
          bottomSize: 660,
          starAlpha: .025,
        );
      case HomeBackgroundVariant.ciruelaTostada:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF180828), Color(0xFF2A102C), Color(0xFF10243B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
          topGlow: Color(0x2CFF3EA5),
          sideGlow: Color(0x24FFB400),
          bottomGlow: Color(0x2000D4FF),
          topSize: 500,
          sideSize: 480,
          bottomSize: 720,
          starAlpha: .035,
        );
      case HomeBackgroundVariant.petroleoDorado:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF0D0822), Color(0xFF111633), Color(0xFF062E3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          topGlow: Color(0x207C3AFF),
          sideGlow: Color(0x24FFB400),
          bottomGlow: Color(0x2B00D4FF),
          topSize: 440,
          sideSize: 510,
          bottomSize: 760,
          starAlpha: .03,
        );
      case HomeBackgroundVariant.naranjaNocturno:
        return const _AuroraPreset(
          baseGradient: LinearGradient(
            colors: [Color(0xFF120620), Color(0xFF1F0D21), Color(0xFF101D31)],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
          topGlow: Color(0x22FF3EA5),
          sideGlow: Color(0x40FF7A1A),
          bottomGlow: Color(0x1A7C3AFF),
          topSize: 430,
          sideSize: 620,
          bottomSize: 700,
          starAlpha: .03,
        );
      case HomeBackgroundVariant.actualSuave:
        return _AuroraPreset(
          baseGradient: const LinearGradient(
            colors: [Color(0xFF14092E), Color(0xFF170A32), Color(0xFF0F2035)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          topGlow: AppColors.aurora1.withValues(alpha: .30),
          sideGlow: AppColors.accentViolet.withValues(alpha: .19),
          bottomGlow: AppColors.aurora3.withValues(alpha: .20),
          topSize: 460,
          sideSize: 520,
          bottomSize: 680,
          starAlpha: .07,
        );
      case HomeBackgroundVariant.current:
        return _AuroraPreset(
          baseGradient: const LinearGradient(
            colors: [AppColors.bgBase, Color(0xFF14092E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          topGlow: AppColors.aurora1.withValues(alpha: 0.5),
          sideGlow: AppColors.accentViolet.withValues(alpha: 0.3),
          bottomGlow: AppColors.aurora3.withValues(alpha: 0.3),
          topSize: 500,
          sideSize: 600,
          bottomSize: 800,
          starAlpha: .15,
        );
    }
  }
}

class _StarsPainter extends CustomPainter {
  final double alpha;

  const _StarsPainter(this.alpha);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    final points = [
      const Offset(0.2, 0.3),
      const Offset(0.6, 0.7),
      const Offset(0.8, 0.2),
      const Offset(0.3, 0.8),
    ];
    for (var p in points) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuroraCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _AuroraCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.2, 1.0],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          inner: AppColors.glassSaturate,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.glassBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bottom-sheet con accesos de cuenta.
void _showAccountMenu(BuildContext context) {
  final store = AppScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (store.isLoggedIn) ...[
                _AccountMenuRow(
                  icon: Icons.account_circle_outlined,
                  label: store.currentUser?.effectiveName ?? 'Mi cuenta',
                  subtitle: store.currentUser?.email ?? '',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.pushNamed(context, '/account');
                  },
                ),
                _AccountMenuRow(
                  icon: Icons.inbox_outlined,
                  label: 'Compartidos conmigo',
                  subtitle: 'Mazos que tus amigos te enviaron',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.pushNamed(context, '/inbox');
                  },
                ),
              ] else
                _AccountMenuRow(
                  icon: Icons.login_rounded,
                  label: 'Iniciar sesión',
                  subtitle: 'Sincroniza tus mazos y conecta con amigos',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.pushNamed(context, '/login');
                  },
                ),
              _AccountMenuRow(
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                subtitle: 'Tema, idioma, accesibilidad, recordatorios',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              _AccountMenuRow(
                icon: Icons.gavel_rounded,
                label: 'Legal y privacidad',
                subtitle: 'Términos, Privacidad, DMCA, Comunidad',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.pushNamed(context, '/legal');
                },
              ),
              if (store.isModerator)
                _AccountMenuRow(
                  icon: Icons.shield_outlined,
                  label: 'Moderación',
                  subtitle: 'Cola de reportes recibidos',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.pushNamed(context, '/moderation');
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _AccountMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _AccountMenuRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.glassSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: .45),
                ),
              ),
              child: Icon(icon, color: AppColors.accentCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (store.isLoggedIn) {
              _showAccountMenu(context);
            } else {
              Navigator.pushNamed(context, '/login');
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.gradPrimary,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Center(
                  child: store.isLoggedIn
                      ? Text(
                          store.currentUser?.initial ?? 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        )
                      : const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              if (store.totalNotifications > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.urgent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.bgBase,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${store.totalNotifications}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔥 Racha ${store.streakDays} días'
                '${store.streakFreezes > 0 ? '  ❄️ ${store.streakFreezes}' : ''}',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                store.isLoggedIn
                    ? 'Hola ${store.currentUser?.effectiveName ?? "Usuario"}'
                    : 'Invitado',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: Icons.settings_outlined,
        ),
        const SizedBox(width: 8),
        if (store.isLoggedIn)
          _IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.notificaciones);
              store.refreshNotificationCount();
            },
            icon: Icons.notifications_none_outlined,
            badgeCount: store.unreadNotifications,
          ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  /// Cuando es > 0 muestra un badge con el número. Usado por la campana para
  /// el conteo de no-leídas.
  final int badgeCount;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.glassBg,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.bgBase, width: 1.5),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          trailing != null ? trailing! : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _MemorizarGrid extends StatelessWidget {
  const _MemorizarGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MemCard(
                title: 'Biblia',
                subtitle: 'Versículos · capítulos · libros',
                emoji: '✝️',
                color: AppColors.accentSun,
                route: '/biblia',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MemCard(
                title: 'Especificar',
                subtitle: 'Pega tu contenido',
                emoji: '✨',
                color: AppColors.accentViolet,
                route: '/especificar',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final String route;

  const _MemCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        height: 104,
        color: AppColors.glassBg,
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Opacity(
                opacity: 0.18,
                child: GlyphIcon(
                  emoji,
                  size: 70,
                  color: AppColors.ink.withValues(alpha: .65),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.5),
                        color.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(child: GlyphIcon(emoji, size: 18)),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitySlider extends StatelessWidget {
  const _CommunitySlider();

  @override
  Widget build(BuildContext context) {
    final decks = AppScope.of(context).decks;
    if (decks.isEmpty) {
      return const _EmptyHomePanel(
        icon: '📚',
        title: 'No hay mazos todavía',
        body:
            'Cuando crees contenido desde Biblia o Especificar, aparecerá aquí.',
      );
    }
    // Mostramos los mazos como un slide ordenado por los que más tarjetas
    // pendientes (débiles/por repasar) tienen, para empujar al usuario hacia
    // lo más urgente primero.
    final sorted = [...decks]
      ..sort((a, b) => b.weakCount.compareTo(a.weakCount));
    final store = AppScope.of(context);
    final groupsById = {for (final g in store.groups) g.id: g};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final deck in sorted) ...[
            Builder(builder: (context) {
              final group =
                  deck.groupId != null ? groupsById[deck.groupId] : null;
              return _CommunityCard(
                emoji: deck.icon,
                title: deck.title,
                stats: '${deck.cards.length} tarjetas',
                weakCount: deck.weakCount,
                groupLabel: group?.name,
                groupEmoji: group?.icon,
                groupColor: group != null ? groupColor(group.id) : null,
                onTap: () {
                  AppScope.of(context).setActiveDeck(deck.id);
                  Navigator.pushNamed(context, '/iniciar');
                },
              );
            }),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

/// Paleta de colores distintivos para las carpetas/grupos. Se asigna de forma
/// estable a partir del id del grupo, para que cada carpeta tenga su propio
/// color consistente entre sesiones.
const List<Color> _groupPalette = [
  AppColors.accentCyan,
  AppColors.accentPink,
  AppColors.accentLime,
  AppColors.accentViolet,
  AppColors.accentSun,
  Color(0xFF4ECDC4),
  Color(0xFFFF8A5B),
  Color(0xFF59B0FF),
];

/// Color distintivo y estable para un grupo, derivado de su id.
Color groupColor(String groupId) =>
    _groupPalette[groupId.hashCode.abs() % _groupPalette.length];

class _CommunityCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String stats;
  /// Tarjetas débiles/por repasar del mazo. > 0 muestra un badge accionable.
  final int weakCount;
  /// Carpeta/grupo del mazo (si aplica): se muestra como chip de color junto
  /// al emoji.
  final String? groupLabel;
  final String? groupEmoji;
  final Color? groupColor;
  /// Promedio de estrellas (0–5) para mazos de comunidad. > 0 muestra un badge
  /// de popularidad con la valoración.
  final double ratingAvg;
  final int ratingCount;
  final VoidCallback? onTap;

  const _CommunityCard({
    required this.emoji,
    required this.title,
    required this.stats,
    this.weakCount = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.groupLabel,
    this.groupEmoji,
    this.groupColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        width: 168,
        padding: const EdgeInsets.all(13),
        color: AppColors.glassBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.glassStrong,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Center(child: GlyphIcon(emoji, size: 24)),
                      ),
                      if (groupLabel != null && groupColor != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: groupColor!.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: groupColor!.withValues(alpha: .5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (groupEmoji != null) ...[
                                  Text(groupEmoji!,
                                      style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                ],
                                Flexible(
                                  child: Text(
                                    groupLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: groupColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (ratingAvg > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentSun.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.accentSun.withValues(alpha: .4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('★',
                            style: TextStyle(
                                color: AppColors.accentSun, fontSize: 11)),
                        const SizedBox(width: 2),
                        Text(
                          ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.accentSun,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (weakCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.urgent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.urgent.withValues(alpha: .4),
                      ),
                    ),
                    child: Text(
                      '$weakCount',
                      style: const TextStyle(
                        color: AppColors.urgent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              stats,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slide horizontal de mazos publicados por la comunidad, con el mismo estilo
/// de tarjeta que "Tus mazos". Carga el overview del backend; si no hay sesión
/// o aún no hay mazos publicados, muestra un panel breve que invita a explorar.
class _HomeCommunitySlider extends StatefulWidget {
  const _HomeCommunitySlider();

  @override
  State<_HomeCommunitySlider> createState() => _HomeCommunitySliderState();
}

class _HomeCommunitySliderState extends State<_HomeCommunitySlider> {
  List<Map<String, dynamic>>? _shares;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = AppScope.of(context);
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final overview = await store.api.getCommunityOverview();
      // Combinamos destacados + populares y deduplicamos por shareId, dejando
      // los más relevantes primero (orden de llegada del backend).
      final featured =
          (overview['featured'] as List? ?? const []).cast<Map<String, dynamic>>();
      final popular =
          (overview['popular'] as List? ?? const []).cast<Map<String, dynamic>>();
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final share in [...featured, ...popular]) {
        final id = (share['shareId'] as String?) ?? (share['title'] as String?) ?? '';
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        merged.add(share);
      }
      if (!mounted) return;
      setState(() => _shares = merged);
    } catch (_) {
      if (!mounted) return;
      setState(() => _shares = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _shareIcon(Map<String, dynamic> share) {
    try {
      final raw = (share['payloadJson'] as String?) ?? '';
      if (raw.isEmpty) return '🌍';
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final icon = (payload['icon'] as String?)?.trim() ?? '';
      return icon.isEmpty ? '🌍' : icon;
    } catch (_) {
      return '🌍';
    }
  }

  /// Línea de popularidad del mazo: importaciones + me gusta (+ nº de
  /// valoraciones cuando las hay), para dar señal social en la tarjeta.
  String _shareStats(Map<String, dynamic> share) {
    final imports = (share['importCount'] as int?) ?? 0;
    final likes = (share['likeCount'] as int?) ?? 0;
    final ratings = (share['ratingCount'] as int?) ?? 0;
    final parts = <String>['$imports 📥', '$likes ❤️'];
    if (ratings > 0) {
      parts.add('$ratings ${ratings == 1 ? 'reseña' : 'reseñas'}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final shares = _shares;
    if (shares != null && shares.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final share in shares) ...[
              _CommunityCard(
                emoji: _shareIcon(share),
                title: (share['title'] as String?) ?? 'Sin título',
                stats: _shareStats(share),
                ratingAvg: (share['ratingAvg'] as num?)?.toDouble() ?? 0,
                ratingCount: (share['ratingCount'] as int?) ?? 0,
                onTap: () => Navigator.pushNamed(context, '/comunidad'),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      );
    }
    // Sin sesión o sin mazos publicados todavía: panel breve que invita.
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/comunidad'),
      child: const _EmptyHomePanel(
        icon: '🌍',
        title: 'Explora la comunidad',
        body: 'Descubre y descarga mazos publicados por otras personas.',
      ),
    );
  }
}

class _CoopBar extends StatelessWidget {
  const _CoopBar();

  @override
  Widget build(BuildContext context) {
    final activeCoop = CoopService.active;

    if (activeCoop == null) {
      return _buildCard(
        context: context,
        title: 'Sala Cooperativa',
        subtitle: 'Crea una sala privada o únete a una partida',
        avatarLabel: '👥',
        avatarColor: AppColors.accentPink,
      );
    }

    return StreamBuilder<CoopRoomState>(
      stream: activeCoop.stateStream,
      initialData: activeCoop.state,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null) {
          return _buildCard(
            context: context,
            title: 'Sala Cooperativa',
            subtitle: 'Crea una sala privada o únete a una partida',
            avatarLabel: '👥',
            avatarColor: AppColors.accentPink,
          );
        }

        final deckName = state.lobbyDeckName;
        final deckSelected = deckName != null && deckName.isNotEmpty;
        final title = deckSelected ? 'Estudiar $deckName en equipo' : 'Sala Cooperativa Activa';
        final subtitle = 'Código: ${state.code} · ${state.memberIds.length}/${state.sessionMaxPlayers} jugadores';
        final avatarLabel = deckSelected ? deckName.characters.first.toUpperCase() : '👥';
        final avatarColor = AppColors.accentLime;

        return _buildCard(
          context: context,
          title: title,
          subtitle: subtitle,
          avatarLabel: avatarLabel,
          avatarColor: avatarColor,
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String avatarLabel,
    required Color avatarColor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cooperativo'),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Stack(
                children: [
                  _SmallAvatar(
                    label: avatarLabel,
                    color: avatarColor,
                  ),
                  Positioned(
                    left: 24,
                    child: _SmallAvatar(label: '+', color: AppColors.accentCyan),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accentLime,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}


class _SmallAvatar extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallAvatar({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: AppColors.bgBase, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FriendsSlider extends StatelessWidget {
  const _FriendsSlider();

  @override
  Widget build(BuildContext context) {
    return const _EmptyHomePanel(
      icon: '🫱🏽‍🫲🏼',
      title: 'Aún no hay amigos conectados',
      body:
          'La lista se llenará cuando conectemos contactos reales o invites a alguien.',
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const _AvatarCircle({
    required this.label,
    required this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ActivityFeed extends StatefulWidget {
  const _ActivityFeed();

  @override
  State<_ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<_ActivityFeed> {
  List<FeedEntry>? _entries;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFeed());
  }

  Future<void> _fetchFeed() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    try {
      final feed = await store.api.feed();
      if (!mounted) return;
      setState(() => _entries = feed);
    } catch (_) {
      // Silent fallback al feed local.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    // Logueado: feed SOLO de amigos (excluye mi propia actividad).
    if (store.isLoggedIn) {
      final myId = store.currentUser?.id;
      final friendsEntries =
          (_entries ?? const <FeedEntry>[]).where((e) => e.userId != myId).toList();

      if (friendsEntries.isNotEmpty) {
        return GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (final raw in friendsEntries.take(5).toList().asMap().entries) ...[
                _RemoteFeedRow(entry: raw.value),
                if (raw.key != 4 && raw.key < friendsEntries.length - 1)
                  const Divider(color: AppColors.glassBorder, height: 20),
              ],
            ],
          ),
        );
      }

      if (_loading && _entries == null) {
        return const GlassCard(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return const _EmptyHomePanel(
        icon: '👋',
        title: 'Sin actividad de amigos',
        body: 'Cuando tus amigos memoricen o logren algo, lo verás aquí.',
      );
    }

    // Fallback local: invitado o feed remoto vacío → mostrar mazos creados.
    final decks = store.decks;
    if (decks.isEmpty) {
      return const _EmptyHomePanel(
        icon: '✨',
        title: 'Sin actividad todavía',
        body: 'Tus mazos creados y repasos aparecerán aquí cuando empieces.',
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          for (final entry in decks.take(3).indexed) ...[
            _FeedItem(
              label: entry.$2.title.characters.first.toUpperCase(),
              color: entry.$2.isBible
                  ? AppColors.accentSun
                  : AppColors.accentCyan,
              name: 'Tú',
              action: 'creaste "${entry.$2.title}"',
              time: entry.$1 == 0 ? 'Ahora' : 'Reciente',
              emoji: entry.$2.icon,
            ),
            if (entry.$1 != decks.take(3).length - 1)
              const Divider(color: AppColors.glassBorder, height: 20),
          ],
        ],
      ),
    );
  }
}

/// Una fila del feed remoto. Mapea por `type` (achievement / activity /
/// share) a iconos y colores distintos; tocar el icono envía una reacción
/// real al backend.
class _RemoteFeedRow extends StatefulWidget {
  final FeedEntry entry;
  const _RemoteFeedRow({required this.entry});

  @override
  State<_RemoteFeedRow> createState() => _RemoteFeedRowState();
}

class _RemoteFeedRowState extends State<_RemoteFeedRow> {
  bool _reacted = false;
  bool _sending = false;

  Future<void> _react() async {
    if (_reacted || _sending) return;
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() => _sending = true);
    try {
      await store.api.reactToFeedEntry(
        entryId: widget.entry.id,
        emoji: '❤️',
      );
      if (!mounted) return;
      setState(() => _reacted = true);
    } catch (e) {
      debugPrint('No se pudo reaccionar al feed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final title = entry.title;
    final description = entry.description;
    final initial = title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?';
    final color = entry.type == FeedEntryType.achievement
        ? AppColors.accentSun
        : entry.type == FeedEntryType.share
            ? AppColors.accentLime
            : AppColors.accentCyan;
    final emoji = entry.type == FeedEntryType.achievement
        ? '🏆'
        : entry.type == FeedEntryType.share
            ? '🤝'
            : '✨';
    return _FeedItem(
      label: initial,
      color: color,
      name: title,
      action: description,
      time: 'Hoy',
      emoji: _reacted ? '❤️' : emoji,
      onEmojiTap: _react,
    );
  }
}

class _EmptyHomePanel extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _EmptyHomePanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Center(child: GlyphIcon(icon, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final String label;
  final Color color;
  final String name;
  final String action;
  final String time;
  final String emoji;
  final VoidCallback? onEmojiTap;

  const _FeedItem({
    required this.label,
    required this.color,
    required this.name,
    required this.action,
    required this.time,
    required this.emoji,
    this.onEmojiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvatarCircle(label: label, color: color, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink,
                    fontFamily: 'Sora',
                  ),
                  children: [
                    TextSpan(
                      text: '$name ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: action),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEmojiTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.glassSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Center(child: GlyphIcon(emoji, size: 18)),
          ),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _NavItem(icon: Icons.home, label: 'Inicio', isActive: true),
          const _NavItem(
            icon: Icons.view_carousel_outlined,
            label: 'Mazos',
            route: '/repasar',
          ),
          const _NavItem(
            icon: Icons.people_outline,
            label: 'Amigos',
            route: '/amigos',
          ),
          const _NavItem(
            icon: Icons.language,
            label: 'Comunidad',
            route: '/comunidad',
          ),
          const _NavItem(
            icon: Icons.pie_chart_outline,
            label: 'Stats',
            route: '/stats',
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? route;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: route == null
            ? null
            : () => Navigator.pushReplacementNamed(context, route!),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: isActive
              ? BoxDecoration(
                  gradient: AppColors.gradPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPink.withValues(alpha: 0.4),
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
                color: isActive ? Colors.white : AppColors.inkMuted,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.inkMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
