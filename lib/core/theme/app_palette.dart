import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brand colors that have no exact Material `ColorScheme` role.
///
/// Read with `context.palette`. A dark theme only needs another instance.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.successText,
    required this.warning,
    required this.warningText,
    required this.danger,
  });

  static const light = AppPalette(
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    accent: AppColors.accentCoral,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    border: AppColors.border,
    success: AppColors.success,
    successText: AppColors.successText,
    warning: AppColors.warning,
    warningText: AppColors.warningText,
    danger: AppColors.errorText,
  );

  final Color primaryDark;
  final Color primaryLight;

  /// Coral accent. Use sparingly (BRAND §4).
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Success icon/fill color. Use [successText] for text.
  final Color success;
  final Color successText;

  /// Decorative only. Always pair with text; use [warningText] for text.
  final Color warning;
  final Color warningText;

  /// Accessible error color, safe for text and for fills behind white labels.
  final Color danger;

  @override
  AppPalette copyWith({
    Color? primaryDark,
    Color? primaryLight,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? success,
    Color? successText,
    Color? warning,
    Color? warningText,
    Color? danger,
  }) {
    return AppPalette(
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
}
