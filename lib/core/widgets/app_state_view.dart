import 'package:flutter/material.dart';

import '../errors/app_failure.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Empty state: icon, title, friendly message and an optional action
/// (APP_FLOW §18).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _StateLayout(
        icon: icon,
        iconColor: context.colors.primary,
        title: title,
        message: message,
        action: actionLabel != null && onAction != null
            ? AppButton.secondary(label: actionLabel!, onPressed: onAction, expand: false)
            : null,
      );
}

/// Error state with a retry action. Pass an [AppFailure] (never a raw
/// exception) so only user-safe text is displayed.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.failure,
    this.onRetry,
    this.title = "Something didn't work",
  });

  final AppFailure failure;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => _StateLayout(
        icon: failure is NetworkFailure ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        iconColor: context.colors.error,
        title: failure is NetworkFailure ? "You're offline" : title,
        message: failure.message,
        action: onRetry == null ? null : AppButton.secondary(label: 'Try again', onPressed: onRetry, expand: false),
      );
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor),
            Gap.lg,
            Text(title, textAlign: TextAlign.center, style: text.titleMedium),
            Gap.sm,
            Text(message, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: context.palette.textSecondary)),
            if (action != null) ...[Gap.xl, action!],
          ],
        ),
      ),
    );
  }
}
