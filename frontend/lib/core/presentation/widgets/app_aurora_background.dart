import 'package:flutter/material.dart';
import '../../theme.dart';

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
