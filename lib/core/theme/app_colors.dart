import 'package:flutter/painting.dart';

/// Raw brand color tokens from `doc/BRAND.md` §4 (Sprelia, purple-led).
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
  static const textSecondary = Color(0xFF77758B);
  static const border = Color(0xFFEAE7F2);
  static const success = Color(0xFF249B70);
  static const warning = Color(0xFFE9A23B);
  static const error = Color(0xFFD95757);

  static const onPrimary = Color(0xFFFFFFFF);
}
