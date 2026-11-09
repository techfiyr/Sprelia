import 'package:flutter/painting.dart';

/// Raw brand color tokens from `doc/BRAND.md` §4 and §12 (Hermione, purple-led).
///
/// Only the theme layer (`lib/core/theme/`) may reference these directly.
/// Feature code reads colors through `Theme.of(context).colorScheme` or
/// `context.palette` so a future dark theme needs no feature changes.
abstract final class AppColors {
  static const primary = Color(0xFF7656D9);
  static const primaryDark = Color(0xFF5235A8);
  static const primaryLight = Color(0xFFF1EBFF);
  static const accentCoral = Color(0xFFFF827A);
  static const background = Color(0xFFFAF9FF);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF20213A);
  /// Darkened from #77758B to meet WCAG AA on every surface (BRAND §12).
  static const textSecondary = Color(0xFF6A687C);
  static const border = Color(0xFFEAE7F2);

  // Status hues: icons, borders and decorative fills (>= 3:1 non-text), except
  // warning, which is decorative only and must always be paired with text.
  static const success = Color(0xFF249B70);
  static const warning = Color(0xFFE9A23B);
  static const error = Color(0xFFD95757);

  // Accessible text variants (>= 4.5:1 on background, surface and primaryLight).
  // Also used as fills behind white labels (e.g. destructive buttons).
  static const successText = Color(0xFF1C7857);
  static const warningText = Color(0xFF945E11);
  static const errorText = Color(0xFFC82D2D);

  static const onPrimary = Color(0xFFFFFFFF);
}
