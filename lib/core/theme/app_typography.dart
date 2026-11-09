import 'package:flutter/material.dart';

/// Typography tokens.
///
/// Scale: `doc/DESIGN_SYSTEM.md` §4. Weights: `doc/BRAND.md` §4 ("medium and
/// semibold weights for headings"), which takes precedence for visual identity.
///
/// Font: Inter is the brand typeface. The font files are NOT bundled yet, so
/// Flutter falls back to the platform sans-serif (Roboto / SF). To enable Inter,
/// add the OFL-licensed TTFs under `assets/fonts/inter/` and declare the `Inter`
/// family in `pubspec.yaml`; no code change is needed.
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static const _heading = FontWeight.w600;
  static const _label = FontWeight.w500;
  static const _regular = FontWeight.w400;

  /// Maps the design-system scale onto Material 3 roles:
  ///
  /// | Design system | Size | Material role     |
  /// |---------------|-----:|-------------------|
  /// | Display       |  32  | displaySmall      |
  /// | H1            |  28  | headlineMedium    |
  /// | H2            |  24  | headlineSmall     |
  /// | H3            |  20  | titleLarge        |
  /// | Body Large    |  16  | bodyLarge         |
  /// | Body          |  14  | bodyMedium        |
  /// | Caption       |  12  | bodySmall         |
  /// | Button        |  15  | labelLarge        |
  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    TextStyle style(double size, FontWeight weight, double height, [Color? color]) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? primaryText,
          letterSpacing: 0,
        );

    return TextTheme(
      displayLarge: style(36, _heading, 1.15),
      displayMedium: style(34, _heading, 1.15),
      displaySmall: style(32, _heading, 1.2),
      headlineLarge: style(30, _heading, 1.2),
      headlineMedium: style(28, _heading, 1.25),
      headlineSmall: style(24, _heading, 1.3),
      titleLarge: style(20, _heading, 1.3),
      titleMedium: style(16, _heading, 1.4),
      titleSmall: style(14, _heading, 1.4),
      bodyLarge: style(16, _regular, 1.5),
      bodyMedium: style(14, _regular, 1.5),
      bodySmall: style(12, _regular, 1.45, secondaryText),
      labelLarge: style(15, FontWeight.w600, 1.3),
      labelMedium: style(12, _label, 1.3),
      labelSmall: style(11, _label, 1.3, secondaryText),
    );
  }
}
