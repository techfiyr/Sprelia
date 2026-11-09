import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_brand.dart';
import 'brand_art.dart';

/// The Hermione logo: a speech bubble holding an open book (an original mark drawn in
/// code, see [HermioneMarkPainter]). Optionally shown with the wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Semantics(
      label: '${AppBrand.name} logo',
      image: true,
      child: SizedBox(
        key: const ValueKey('brand-logo'),
        width: size,
        height: size,
        child: const CustomPaint(painter: HermioneMarkPainter()),
      ),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        Gap.md,
        Text(
          AppBrand.name,
          style: context.textStyles.headlineMedium?.copyWith(
            color: BrandPalette.plum,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
