import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large selectable card for onboarding and settings (DESIGN_SYSTEM §10:
/// "large selection cards"). Selection is shown by border, tint AND a check
/// icon, never by color alone, and is announced to screen readers.
class AppSelectionTile extends StatelessWidget {
  const AppSelectionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.multiSelect = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  /// Checkbox semantics (multi-select) instead of radio semantics.
  final bool multiSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    final text = context.textStyles;
    final borderColor = selected ? colors.primary : palette.border;

    return Semantics(
      selected: selected,
      checked: multiSelect ? selected : null,
      inMutuallyExclusiveGroup: !multiSelect,
      button: true,
      enabled: enabled,
      child: Material(
        color: selected ? palette.primaryLight : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, Gap.md],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: text.titleMedium?.copyWith(
                            color: enabled ? (selected ? palette.primaryDark : palette.textPrimary) : palette.textSecondary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: text.bodyMedium?.copyWith(color: palette.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  Gap.md,
                  ExcludeSemantics(
                    child: Icon(
                      selected
                          ? (multiSelect ? Icons.check_box_rounded : Icons.check_circle_rounded)
                          : (multiSelect ? Icons.check_box_outline_blank_rounded : Icons.radio_button_unchecked),
                      color: selected ? colors.primary : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
