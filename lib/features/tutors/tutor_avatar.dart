import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_theme.dart';
import 'tutor.dart';

/// The single tutor avatar widget used across the app (keeps tutors consistent).
///
/// Uses the approved image from [AppAssets.tutorAvatar] when one is available and
/// bundled; otherwise renders the documented PLACEHOLDER (initial on a brand tint).
/// Every image is cropped to the same circle and scale.
class TutorAvatar extends StatelessWidget {
  const TutorAvatar({super.key, required this.tutor, this.size = 48, this.active = false});

  final Tutor tutor;
  final double size;
  final bool active;

  Color _toneColor(BuildContext context) => switch (tutor.tone) {
        TutorTone.primary => context.colors.primary,
        TutorTone.primaryDark => context.palette.primaryDark,
        TutorTone.accent => context.palette.accent,
      };

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context);
    // Coral is too light for text; keep initials dark on the accent tint.
    final initialColor = tutor.tone == TutorTone.accent ? context.palette.textPrimary : color;
    final asset = AppAssets.tutorAvatar(tutor.id);
    if (asset != null) {
      return Semantics(
        label: '${tutor.name} avatar',
        image: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: active ? color : Colors.transparent, width: size / 16),
          ),
          child: ClipOval(
            child: Image.asset(
              asset.path,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: '${tutor.name} avatar (placeholder)',
      image: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: active ? color : Colors.transparent, width: size / 16),
        ),
        alignment: Alignment.center,
        child: ExcludeSemantics(
          child: Text(
            tutor.name[0],
            style: TextStyle(color: initialColor, fontSize: size * 0.42, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
