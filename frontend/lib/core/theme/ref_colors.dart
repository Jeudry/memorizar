import 'package:flutter/material.dart';

import '../theme.dart';

/// Semantic colour palette shared across all reference screens. Wraps the raw
/// design-system colours from [AppColors] and exposes the gradients that the
/// UI uses for buttons, accents and surfaces.
class RefColors {
  static const bg = AppColors.bgBase;
  static const glass = AppColors.glassBg;
  static const glassStrong = AppColors.glassStrong;
  static const glassSoft = AppColors.glassSoft;
  static const border = AppColors.glassBorder;
  static const inner = AppColors.glassInner;
  static const ink = AppColors.ink;
  static const muted = AppColors.inkMuted;
  static const dim = AppColors.inkDim;
  static const pink = AppColors.accentPink;
  static const sun = AppColors.accentSun;
  static const cyan = AppColors.accentCyan;
  static const violet = AppColors.accentViolet;
  static const lime = AppColors.accentLime;
  static const urgent = AppColors.urgent;
  static const successInk = Color(0xFF06280F);

  static const primary = LinearGradient(
    colors: [pink, sun],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cool = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const success = LinearGradient(
    colors: [lime, Color(0xFF3ED97A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const purple = LinearGradient(
    colors: [violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const limeGrad = LinearGradient(
    colors: [lime, Color(0xFF5BE47D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Translucent overlays used over the aurora background. Kept separate from
/// [RefColors] because these are pre-mixed alpha values that match the HTML
/// design reference.
class HtmlRefColors {
  static const glassBg = Color(0x1AFFFFFF);
  static const glassSoft = Color(0x0FFFFFFF);
  static const glassStrong = Color(0x29FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);
  static const bookSelected = Color(0x33FF3EA5);
  static const bookPartial = Color(0x2600D4FF);
  static const bookPartialBorder = Color(0x9900D4FF);
}
