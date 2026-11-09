import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../tutors/tutor.dart';
import '../tutors/tutor_avatar.dart';

class PrepareScreen extends StatelessWidget {
  const PrepareScreen({super.key, required this.tutorId});

  final String tutorId;

  @override
  Widget build(BuildContext context) {
    final tutor = tutorById(tutorId);
    final text = context.textStyles;
    return Scaffold(
      appBar: AppBar(title: const Text('Get ready')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: TutorAvatar(tutor: tutor, size: 96)),
              const SizedBox(height: 16),
              Text(tutor.name, textAlign: TextAlign.center, style: text.headlineSmall),
              Text(tutor.title,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: context.palette.textSecondary)),
              Gap.xl,
              _InfoRow(icon: Icons.chat_bubble_outline, label: 'Mode', value: 'Free conversation'),
              _InfoRow(icon: Icons.flag_outlined, label: 'Goal', value: 'Speak naturally for a few minutes'),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Daily free time',
                value: '${AppConfig.freeDailySecondsDisplay ~/ 60} minutes',
              ),
              const Spacer(),
              AppCard(
                tone: AppCardTone.tinted,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Your voice is streamed to our AI provider to power the conversation. '
                  'We save the text transcript to create your feedback. Raw audio is not stored.',
                  style: text.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Start Conversation',
                onPressed: () => context.pushReplacement(AppRoutes.conversation(tutor.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final muted = context.palette.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 12),
          Text(label, style: text.bodyMedium?.copyWith(color: muted)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
