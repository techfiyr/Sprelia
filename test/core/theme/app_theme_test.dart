import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/theme/app_colors.dart';
import 'package:speakdaily/core/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final theme = AppTheme.light();

  test('uses the BRAND.md palette', () {
    expect(theme.colorScheme.primary, const Color(0xFF7656D9));
    expect(theme.colorScheme.error, const Color(0xFFD95757));
    expect(theme.colorScheme.onSurface, const Color(0xFF20213A));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFAF9FF));
    expect(theme.brightness, Brightness.light);
    expect(theme.extension<AppPalette>(), AppPalette.light);
  });

  test('typography follows the DESIGN_SYSTEM scale', () {
    final t = theme.textTheme;
    expect(t.displaySmall!.fontSize, 32);
    expect(t.headlineMedium!.fontSize, 28);
    expect(t.headlineSmall!.fontSize, 24);
    expect(t.titleLarge!.fontSize, 20);
    expect(t.bodyLarge!.fontSize, 16);
    expect(t.bodyMedium!.fontSize, 14);
    expect(t.bodySmall!.fontSize, 12);
    expect(t.labelLarge!.fontSize, 15);
    expect(t.headlineMedium!.fontWeight, FontWeight.w600);
    expect(t.bodyMedium!.fontFamily, 'Inter');
  });

  group('WCAG AA contrast (4.5:1) for core text pairs', () {
    test('primary text on background and surface', () {
      expect(contrast(AppColors.textPrimary, AppColors.background), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textPrimary, AppColors.surface), greaterThanOrEqualTo(4.5));
    });
    test('button label on primary', () {
      expect(contrast(AppColors.onPrimary, AppColors.primary), greaterThanOrEqualTo(4.5));
    });
    test('primaryDark on primaryLight (tinted surfaces)', () {
      expect(contrast(AppColors.primaryDark, AppColors.primaryLight), greaterThanOrEqualTo(4.5));
    });
  });

  test('component radii come from tokens', () {
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, AppRadius.cardAll);
    expect(AppRadius.button, inInclusiveRange(14, 18));
    expect(AppRadius.input, inInclusiveRange(12, 16));
  });
}
