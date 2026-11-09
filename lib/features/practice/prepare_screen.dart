import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../tutors/tutor.dart';
import '../tutors/tutor_avatar.dart';

class PrepareScreen extends StatelessWidget {
  const PrepareScreen({super.key, required this.tutorId});

  final String tutorId;

  @override
  Widget build(BuildContext context) {
    final tutor = tutorById(tutorId);
    final text = Theme.of(context).textTheme;
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
                  style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
              const SizedBox(height: 24),
              _InfoRow(icon: Icons.chat_bubble_outline, label: 'Mode', value: 'Free conversation'),
              _InfoRow(icon: Icons.flag_outlined, label: 'Goal', value: 'Speak naturally for a few minutes'),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Daily free time',
                value: '${AppConfig.freeDailySeconds ~/ 60} minutes',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Your voice is streamed to our AI provider to power the conversation. '
                  'We save the text transcript to create your feedback. Raw audio is not stored.',
                  style: text.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pushReplacement('/conversation/${tutor.id}'),
                child: const Text('Start Conversation'),
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.inkMuted),
          const SizedBox(width: 12),
          Text(label, style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
