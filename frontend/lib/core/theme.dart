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
  /// Light theme — usa los mismos accents pero superficies claras. La aurora
  /// del fondo se atenúa vía la aurora widget (variant) si el usuario quiere
  /// más fidelidad.
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F4FB),
      textTheme: GoogleFonts.soraTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: const Color(0xFF1B1130),
        displayColor: const Color(0xFF1B1130),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPink,
        secondary: AppColors.accentSun,
        surface: Color(0xFFFFFFFF),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B1130),
        contentTextStyle: GoogleFonts.sora(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        insetPadding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      ),
    );
  }

  /// Derives a [ThemeData] from [base] applying accessibility tweaks.
  ///
  /// - [dyslexia]: swaps the text theme to `Atkinson Hyperlegible` (a
  ///   dyslexia-friendly typeface bundled with `google_fonts`). OpenDyslexic
  ///   is NOT available via google_fonts, so we fall back to Atkinson which
  ///   is the closest hyperlegible option without bundling a font asset.
  /// - [bigFont]: scales every text style by 1.20 via `apply(fontSizeFactor:)`.
  static ThemeData withAccessibility(
    ThemeData base, {
    bool dyslexia = false,
    bool bigFont = false,
  }) {
    TextTheme textTheme = base.textTheme;

    if (dyslexia) {
      // Preserve existing colors/weights from base.textTheme.
      textTheme = GoogleFonts.atkinsonHyperlegibleTextTheme(textTheme);
    }

    if (bigFont) {
      textTheme = textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontSize: textTheme.displayLarge?.fontSize ?? 57),
        displayMedium: textTheme.displayMedium?.copyWith(fontSize: textTheme.displayMedium?.fontSize ?? 45),
        displaySmall: textTheme.displaySmall?.copyWith(fontSize: textTheme.displaySmall?.fontSize ?? 36),
        headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: textTheme.headlineLarge?.fontSize ?? 32),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: textTheme.headlineMedium?.fontSize ?? 28),
        headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: textTheme.headlineSmall?.fontSize ?? 24),
        titleLarge: textTheme.titleLarge?.copyWith(fontSize: textTheme.titleLarge?.fontSize ?? 22),
        titleMedium: textTheme.titleMedium?.copyWith(fontSize: textTheme.titleMedium?.fontSize ?? 16),
        titleSmall: textTheme.titleSmall?.copyWith(fontSize: textTheme.titleSmall?.fontSize ?? 14),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: textTheme.bodyLarge?.fontSize ?? 16),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: textTheme.bodyMedium?.fontSize ?? 14),
        bodySmall: textTheme.bodySmall?.copyWith(fontSize: textTheme.bodySmall?.fontSize ?? 12),
        labelLarge: textTheme.labelLarge?.copyWith(fontSize: textTheme.labelLarge?.fontSize ?? 14),
        labelMedium: textTheme.labelMedium?.copyWith(fontSize: textTheme.labelMedium?.fontSize ?? 12),
        labelSmall: textTheme.labelSmall?.copyWith(fontSize: textTheme.labelSmall?.fontSize ?? 11),
      );
      textTheme = textTheme.apply(fontSizeFactor: 1.2);
    }

    return base.copyWith(textTheme: textTheme);
  }

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
      // Dark glassy snackbar so any leftover ScaffoldMessenger calls match the
      // app instead of the default white Material toast.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.glassStrong,
        contentTextStyle: GoogleFonts.sora(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        insetPadding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      ),
    );
  }
}
