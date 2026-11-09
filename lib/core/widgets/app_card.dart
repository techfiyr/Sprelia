import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppCardTone { surface, tinted }

/// Rounded card with a light border and no heavy shadow (BRAND §4).
/// Tappable when [onTap] is set; the ink ripple follows the card radius.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.tone = AppCardTone.surface,
    this.large = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final AppCardTone tone;

  /// Large feature card (20 px radius) instead of the standard 16 px.
  final bool large;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = large ? AppRadius.cardLargeAll : AppRadius.cardAll;
    final palette = context.palette;
    final card = Card(
      color: tone == AppCardTone.tinted ? palette.primaryLight : null,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tone == AppCardTone.tinted ? palette.primaryLight : palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, borderRadius: radius, child: Padding(padding: padding, child: child)),
    );
    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, button: onTap != null, child: card);
  }
}
