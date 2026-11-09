import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

/// The only button features should use (DESIGN_SYSTEM §6: primary, secondary,
/// text-only, destructive, loading and disabled states).
///
/// - `onPressed == null` → disabled.
/// - `isLoading` → disabled, shows a spinner, keeps its size, and announces
///   "<label>, loading" to screen readers.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width (default for primary/secondary/destructive).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final colors = context.colors;

    final spinnerColor = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.destructive => colors.onPrimary,
      _ => colors.primary,
    };
    final Widget content = isLoading
        ? Semantics(
            label: '$label, loading',
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), Gap.sm],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: effectiveOnPressed, child: content),
      AppButtonVariant.secondary => OutlinedButton(onPressed: effectiveOnPressed, child: content),
      AppButtonVariant.text => TextButton(onPressed: effectiveOnPressed, child: content),
      AppButtonVariant.destructive => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          child: content,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
