import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'tutor.dart';
import 'tutor_avatar.dart';

class TutorsScreen extends StatelessWidget {
  const TutorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your tutor')),
      body: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: tutors.length,
        separatorBuilder: (_, _) => Gap.md,
        itemBuilder: (context, i) {
          final t = tutors[i];
          return Opacity(
            opacity: t.available ? 1 : 0.55,
            child: AppCard(
                  onTap: t.available ? () => context.push(AppRoutes.prepare(t.id)) : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TutorAvatar(tutor: t, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.name} · ${t.title}', style: text.titleSmall),
                            const SizedBox(height: 4),
                            Text(t.personality, style: text.bodyMedium),
                            const SizedBox(height: 2),
                            Text('${t.focus} · ${t.levels}',
                                style: text.bodySmall),
                            if (!t.available) ...[
                              const SizedBox(height: 6),
                              Text('Coming soon',
                                  style: text.labelSmall),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }
}
