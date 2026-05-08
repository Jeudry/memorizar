import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import 'glyph_icon.dart';

class HomeScreen extends StatelessWidget {
  final HomeBackgroundVariant backgroundVariant;

  const HomeScreen({
    super.key,
    this.backgroundVariant = HomeBackgroundVariant.actualSuave,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Aurora Background
          AppAuroraBackground(variant: backgroundVariant),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Header
                  const _AppHeader(),
                  const SizedBox(height: 18),

                  // Hero Section (Pendientes)
                  const _HeroSection(),
                  const SizedBox(height: 18),

                  // Memorizar algo nuevo
                  const _SectionHeader(title: 'Memorizar algo nuevo'),
                  const _MemorizarGrid(),
                  const SizedBox(height: 12),
                  const _PremiumHomeCard(),
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

                  // Community Bar
                  const _CoopBar(),
                  const SizedBox(height: 18),

                  // Amigos
                  _SectionHeader(
                    title: 'Amigos',
                    trailing: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/amigos'),
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
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (store.isLoggedIn)
              _AccountMenuRow(
                icon: Icons.account_circle_outlined,
                label: store.currentUser?.displayName ?? 'Mi cuenta',
                subtitle: store.currentUser?.email ?? '',
                onTap: () => Navigator.of(sheetCtx).pop(),
              )
            else
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
              icon: Icons.gavel_rounded,
              label: 'Legal y privacidad',
              subtitle: 'Términos, Privacidad, DMCA, Comunidad',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                Navigator.pushNamed(context, '/legal');
              },
            ),
            _AccountMenuRow(
              icon: Icons.shield_outlined,
              label: 'Moderación',
              subtitle: 'Cola de reportes recibidos',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                Navigator.pushNamed(context, '/moderation');
              },
            ),
            if (store.isLoggedIn)
              _AccountMenuRow(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                subtitle: 'Cerrar sesión en este dispositivo',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  store.logout();
                },
              ),
          ],
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
          onTap: () => _showAccountMenu(context),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.gradPrimary,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔥 Racha ${store.streakDays} días',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Hola Ana',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _IconButton(onPressed: () {}, icon: Icons.wb_sunny_outlined),
        const SizedBox(width: 8),
        _IconButton(
          onPressed: () {},
          icon: Icons.notifications_none_outlined,
          hasDot: true,
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool hasDot;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.hasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
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
          if (hasDot)
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPink,
                  boxShadow: [
                    BoxShadow(color: AppColors.accentPink, blurRadius: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dueCards = store.dueCards;
    final topCards = dueCards.take(2).toList();
    if (!store.hasDecks) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.glassStrong,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Text(
                    'INICIO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  '0 min total',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Listo para memorizar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea un mazo abajo y empieza una sesión cuando tengas contenido preparado.',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassStrong,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Text(
                      'PENDIENTE ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPink,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Color(0x80FF3EA5), blurRadius: 10),
                        ],
                      ),
                      child: Text(
                        '${store.weakCards}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '~${store.estimatedPendingMinutes} min total',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < topCards.length; i++) ...[
            _HeroItem(
              emoji: topCards[i].icon,
              title: topCards[i].front,
              subtitle:
                  '${topCards[i].source} · retención ${topCards[i].retention}%',
              eta: '~${(topCards[i].lapses + 3).clamp(3, 7)} min',
              isUrgent: topCards[i].retention < 50,
              isToday: topCards[i].retention >= 50,
              isPriority: i == 0,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/repasar'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ver los ${dueCards.length} pendientes',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.inkMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String eta;
  final bool isUrgent;
  final bool isToday;
  final bool isPriority;

  const _HeroItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.eta,
    this.isUrgent = false,
    this.isToday = false,
    this.isPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isUrgent
        ? AppColors.urgent
        : (isToday ? AppColors.accentSun : AppColors.accentLime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPriority ? AppColors.glassStrong : AppColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPriority
              ? AppColors.urgent.withValues(alpha: 0.30)
              : AppColors.glassBorder,
        ),
        boxShadow: isPriority
            ? [
                BoxShadow(
                  color: AppColors.urgent.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(child: GlyphIcon(emoji, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              eta,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 18),
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
    return Row(
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
        padding: const EdgeInsets.all(16),
        height: 132,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

class _PremiumHomeCard extends StatelessWidget {
  const _PremiumHomeCard();

  @override
  Widget build(BuildContext context) {
    final isPremium = AppScope.of(context).isPremium;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/premium'),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        color: AppColors.glassBg,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.gradPrimary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPink.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _SmallStatusPill(isPremium ? 'Activo' : 'Próximamente'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quizes inteligentes, sin anuncios y ejercicios avanzados.',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  final String label;

  const _SmallStatusPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSun.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentSun.withValues(alpha: .42)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentSun,
          fontSize: 10,
          fontWeight: FontWeight.w900,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final deck in decks.take(4)) ...[
            _CommunityCard(
              emoji: deck.icon,
              title: deck.title,
              stats:
                  '${deck.cards.length} tarjetas · ${deck.retention}% retención',
              rating: (4 + deck.retention / 100).toStringAsFixed(1),
              onTap: () {
                AppScope.of(context).setActiveDeck(deck.id);
                Navigator.pushNamed(context, '/iniciar');
              },
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String stats;
  final String rating;
  final VoidCallback? onTap;

  const _CommunityCard({
    required this.emoji,
    required this.title,
    required this.stats,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(12),
        color: AppColors.glassBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.glassStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Center(child: GlyphIcon(emoji, size: 18)),
                ),
                Text(
                  '★ $rating',
                  style: const TextStyle(
                    color: AppColors.accentSun,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stats,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoopBar extends StatelessWidget {
  const _CoopBar();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.hasDecks) {
      return const _EmptyHomePanel(
        icon: '🤝',
        title: 'Cooperativo listo para tus mazos',
        body: 'Crea primero contenido real para abrir una sala de estudio.',
      );
    }
    final deck = store.activeDeck;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Stack(
              children: [
                _SmallAvatar(
                  label: deck.title.characters.first.toUpperCase(),
                  color: AppColors.accentPink,
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
                  'Estudiar ${deck.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${deck.cards.length} tarjetas · sala privada',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accentLime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentLime, Color(0xFF3ED97A)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Abrir',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
  List<dynamic>? _entries;
  bool _loading = false;
  bool _attempted = false;

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
      _attempted = true;
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

    // Logueado con datos del backend.
    if (store.isLoggedIn && _entries != null && _entries!.isNotEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final raw in _entries!.take(5).toList().asMap().entries) ...[
              _RemoteFeedRow(entry: raw.value as Map<String, dynamic>),
              if (raw.key != 4 && raw.key < _entries!.length - 1)
                const Divider(color: AppColors.glassBorder, height: 20),
            ],
          ],
        ),
      );
    }

    if (store.isLoggedIn && _loading && _entries == null) {
      return const GlassCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
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
/// share) a iconos y colores distintos.
class _RemoteFeedRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _RemoteFeedRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final type = (entry['type'] as String?) ?? '';
    final title = (entry['title'] as String?) ?? '';
    final description = (entry['description'] as String?) ?? '';
    final emoji = (entry['emoji'] as String?) ?? '';
    final initial = title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?';
    final color = type == 'achievement'
        ? AppColors.accentSun
        : type == 'share'
            ? AppColors.accentLime
            : AppColors.accentCyan;
    return _FeedItem(
      label: initial,
      color: color,
      name: title,
      action: description,
      time: 'Hoy',
      emoji: emoji.isEmpty ? '✨' : emoji,
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

  const _FeedItem({
    required this.label,
    required this.color,
    required this.name,
    required this.action,
    required this.time,
    required this.emoji,
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.glassSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Center(child: GlyphIcon(emoji, size: 18)),
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
