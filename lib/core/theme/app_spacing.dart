import 'package:flutter/widgets.dart';

/// Spacing tokens on a 4 px base grid (`doc/BRAND.md` §4, names from
/// `doc/DESIGN_SYSTEM.md` §5).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double section = 48;

  /// Default horizontal padding for screen content.
  static const double screen = lg;

  /// Minimum touch target (DESIGN_SYSTEM §12: 44–48 px).
  static const double minTouchTarget = 48;

  static const screenPadding = EdgeInsets.all(screen);
  static const cardPadding = EdgeInsets.all(lg);
}

/// Vertical / horizontal gaps for use in `Column` / `Row` children.
abstract final class Gap {
  static const xs = SizedBox(width: AppSpacing.xs, height: AppSpacing.xs);
  static const sm = SizedBox(width: AppSpacing.sm, height: AppSpacing.sm);
  static const md = SizedBox(width: AppSpacing.md, height: AppSpacing.md);
  static const lg = SizedBox(width: AppSpacing.lg, height: AppSpacing.lg);
  static const xl = SizedBox(width: AppSpacing.xl, height: AppSpacing.xl);
  static const xxl = SizedBox(width: AppSpacing.xxl, height: AppSpacing.xxl);
}
