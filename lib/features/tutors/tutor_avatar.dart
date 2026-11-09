import 'package:flutter/material.dart';

import 'tutor.dart';

class TutorAvatar extends StatelessWidget {
  const TutorAvatar({super.key, required this.tutor, this.size = 48, this.active = false});

  final Tutor tutor;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tutor.color.withValues(alpha: 0.12),
        border: Border.all(
          color: active ? tutor.color : Colors.transparent,
          width: size / 16,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        tutor.name[0],
        style: TextStyle(
          color: tutor.color,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
