import 'package:flutter/material.dart';

class GlyphIcon extends StatelessWidget {
  final String glyph;
  final double size;
  final Color? color;

  const GlyphIcon(this.glyph, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Colors.white;

    switch (glyph) {
      case '🇫🇷':
        return _FlagIcon(
          size: size,
          colors: const [Color(0xFF244AA5), Colors.white, Color(0xFFE84A5F)],
        );
      case '🇯🇵':
        return _JapanFlag(size: size);
      case '✝️':
        return Icon(Icons.menu_book_rounded, size: size, color: iconColor);
      case '✨':
        return Icon(Icons.auto_awesome_rounded, size: size, color: iconColor);
      case '🧠':
        return Icon(Icons.psychology_rounded, size: size, color: iconColor);
      case '🌍':
        return Icon(Icons.public_rounded, size: size, color: iconColor);
      case '🧪':
        return Icon(Icons.science_rounded, size: size, color: iconColor);
      case '📜':
        return Icon(Icons.article_rounded, size: size, color: iconColor);
      case '🎨':
        return Icon(Icons.palette_rounded, size: size, color: iconColor);
      case '💻':
        return Icon(Icons.laptop_mac_rounded, size: size, color: iconColor);
      case '💊':
        return Icon(Icons.medication_rounded, size: size, color: iconColor);
      case '🌌':
        return Icon(Icons.auto_awesome_rounded, size: size, color: iconColor);
      case '🔥':
        return Icon(
          Icons.local_fire_department_rounded,
          size: size,
          color: iconColor,
        );
      case '🎯':
        return Icon(Icons.track_changes_rounded, size: size, color: iconColor);
      case '⚡':
        return Icon(Icons.bolt_rounded, size: size, color: iconColor);
      case '⋯':
        return Icon(Icons.more_horiz_rounded, size: size, color: iconColor);
      case '🎤':
        return Icon(Icons.mic_rounded, size: size, color: iconColor);
      case '🎉':
        return Icon(Icons.celebration_rounded, size: size, color: iconColor);
      case '🤝':
        return Icon(
          Icons.handshake_rounded,
          size: size,
          color: color ?? const Color(0xFFFFD76A),
        );
      case '👏':
        return Icon(Icons.task_alt_rounded, size: size, color: iconColor);
      case '🌱':
        return Icon(Icons.spa_rounded, size: size, color: iconColor);
      case '🫁':
        return Icon(Icons.air_rounded, size: size, color: iconColor);
      default:
        return Icon(Icons.auto_stories_rounded, size: size, color: iconColor);
    }
  }
}

class _FlagIcon extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _FlagIcon({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: .55)),
        ),
        child: SizedBox(
          width: size * 1.25,
          height: size * .82,
          child: Row(
            children: [
              for (final color in colors)
                Expanded(child: ColoredBox(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JapanFlag extends StatelessWidget {
  final double size;

  const _JapanFlag({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .12),
      child: Container(
        width: size * 1.25,
        height: size * .82,
        color: Colors.white,
        alignment: Alignment.center,
        child: Container(
          width: size * .32,
          height: size * .32,
          decoration: const BoxDecoration(
            color: Color(0xFFBC002D),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
