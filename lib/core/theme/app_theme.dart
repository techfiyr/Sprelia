import 'package:flutter/material.dart';

/// Premium, clean light theme.
class AppColors {
  static const primary = Color(0xFF3B5BDB);
  static const primarySoft = Color(0xFFE7ECFF);
  static const ink = Color(0xFF14171F);
  static const inkMuted = Color(0xFF5B6272);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F7FB);
  static const border = Color(0xFFE4E7EE);
  static const success = Color(0xFF1F9D63);
  static const warning = Color(0xFFE08A00);
  static const danger = Color(0xFFD64545);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final text = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
