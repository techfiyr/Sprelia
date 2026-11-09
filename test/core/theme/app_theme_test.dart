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
    // Accessible error red (BRAND §12) for text and destructive fills.
    expect(theme.colorScheme.error, const Color(0xFFC82D2D));
    expect(AppColors.error, const Color(0xFFD95757)); // decorative brand hue kept
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

  group('WCAG AA contrast (BRAND §12)', () {
    const surfaces = {
      'background': AppColors.background,
      'surface': AppColors.surface,
      'primaryLight': AppColors.primaryLight,
    };
    const textTokens = {
      'textPrimary': AppColors.textPrimary,
      'textSecondary': AppColors.textSecondary,
      'primaryDark': AppColors.primaryDark,
      'successText': AppColors.successText,
      'warningText': AppColors.warningText,
      'errorText': AppColors.errorText,
    };
    for (final t in textTokens.entries) {
      for (final s in surfaces.entries) {
        test('${t.key} text on ${s.key} >= 4.5:1', () {
          expect(contrast(t.value, s.value), greaterThanOrEqualTo(4.5));
        });
      }
    }

    test('white label on primary button >= 4.5:1', () {
      expect(contrast(AppColors.onPrimary, AppColors.primary), greaterThanOrEqualTo(4.5));
    });

    test('white label on destructive button >= 4.5:1', () {
      expect(contrast(AppColors.onPrimary, AppTheme.light().colorScheme.error), greaterThanOrEqualTo(4.5));
    });

    test('text primary on coral accent >= 4.5:1', () {
      expect(contrast(AppColors.textPrimary, AppColors.accentCoral), greaterThanOrEqualTo(4.5));
    });

    test('meaningful non-text colors >= 3:1 on surfaces', () {
      for (final c in [AppColors.primary, AppColors.success, AppColors.error]) {
        expect(contrast(c, AppColors.surface), greaterThanOrEqualTo(3));
      }
    });

    test('theme text roles use accessible tokens', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.onSurfaceVariant, AppColors.textSecondary);
      expect(theme.textTheme.bodySmall!.color, AppColors.textSecondary);
      expect(theme.extension<AppPalette>()!.danger, AppColors.errorText);
    });
  });

  test('component radii come from tokens', () {
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, AppRadius.cardAll);
    expect(AppRadius.button, inInclusiveRange(14, 18));
    expect(AppRadius.input, inInclusiveRange(12, 16));
  });
}
