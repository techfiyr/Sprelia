import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Brand-colored circular indicator.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 32, this.semanticLabel = 'Loading'});

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        child: SizedBox.square(
          dimension: size,
          child: CircularProgressIndicator(strokeWidth: size / 10),
        ),
      );
}

/// Centered full-area loading state with an optional message.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLoadingIndicator(semanticLabel: message ?? 'Loading'),
            if (message != null) ...[
              Gap.lg,
              Text(message!, textAlign: TextAlign.center, style: context.textStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// Static skeleton block for content placeholders. No shimmer animation, so it
/// respects reduced-motion preferences by default.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.width = double.infinity, this.height = 16, this.radius = AppRadius.small});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.palette.border,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}
