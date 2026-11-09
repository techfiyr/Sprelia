import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'tutor.dart';

/// PLACEHOLDER avatar: the tutor's initial on a brand-tinted circle.
/// Final illustrated portraits (BRAND §6) do not exist yet; they will live in
/// `assets/tutors/<id>/` and replace this rendering.
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
