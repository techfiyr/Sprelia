import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_brand.dart';

/// PLACEHOLDER logo. The final Sprelia logo (speech bubble + voice wave,
/// `doc/BRAND.md` §5) has not been designed yet. This uses a stock Material
/// icon in a brand-colored tile and must be replaced by the approved asset
/// under `assets/branding/logo/` once it exists.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Semantics(
      label: '${AppBrand.name} logo (placeholder)',
      image: true,
      child: Container(
        key: const ValueKey('brand-logo-placeholder'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(Icons.graphic_eq_rounded, color: context.colors.onPrimary, size: size * 0.55),
      ),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        Gap.md,
        Text(AppBrand.name, style: context.textStyles.headlineSmall?.copyWith(color: context.palette.primaryDark)),
      ],
    );
  }
}
