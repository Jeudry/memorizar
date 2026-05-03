import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgBase = Color(0xFF14092E);
  static const aurora1 = Color(0x2FFF3EA5);
  static const aurora2 = Color(0x23FFB400);
  static const aurora3 = Color(0x2900D4FF);

  static const ink = Color(0xFFFFFFFF);
  static const inkMuted = Color(0xB3FFFFFF);
  static const inkDim = Color(0x80FFFFFF);

  static const glassBg = Color(0xCC3B285C);
  static const glassStrong = Color(0xE04A326F);
  static const glassSoft = Color(0xBF31204F);
  static const glassBorder = Color(0x668C74B4);
  static const glassInner = Color(0x4DA48DCA);

  static const accentPink = Color(0xFFFF3EA5);
  static const accentSun = Color(0xFFFFB400);
  static const accentCyan = Color(0xFF00D4FF);
  static const accentViolet = Color(0xFF7C3AFF);
  static const accentLime = Color(0xFFA0FF78);
  static const urgent = Color(0xFFFF5A8A);

  static const gradPrimary = LinearGradient(
    colors: [Color(0xFFFF3EA5), Color(0xFFFFB400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ColorFilter glassSaturate = ColorFilter.matrix([
    1.5,
    0,
    0,
    0,
    0,
    0,
    1.5,
    0,
    0,
    0,
    0,
    0,
    1.5,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      textTheme: GoogleFonts.soraTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPink,
        secondary: AppColors.accentSun,
        surface: AppColors.glassBg,
      ),
    );
  }
}
