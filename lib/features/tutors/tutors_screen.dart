import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'tutor.dart';
import 'tutor_avatar.dart';

class TutorsScreen extends StatelessWidget {
  const TutorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your tutor')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tutors.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = tutors[i];
          return Opacity(
            opacity: t.available ? 1 : 0.55,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: t.available ? () => context.push('/prepare/${t.id}') : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TutorAvatar(tutor: t, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.name} · ${t.title}',
                                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(t.personality, style: text.bodyMedium),
                            const SizedBox(height: 2),
                            Text('${t.focus} · ${t.levels}',
                                style: text.bodySmall?.copyWith(color: AppColors.inkMuted)),
                            if (!t.available) ...[
                              const SizedBox(height: 6),
                              Text('Coming soon',
                                  style: text.labelSmall?.copyWith(color: AppColors.inkMuted)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
