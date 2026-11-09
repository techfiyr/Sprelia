import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../tutors/tutor.dart';
import '../tutors/tutor_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning!';
    if (h < 18) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final emma = tutorById('emma');
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.insights_outlined), onPressed: () => context.push('/progress')),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/profile')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(_greeting(), style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ready to improve your English?',
              style: text.bodyLarge?.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's goal", style: text.labelLarge?.copyWith(color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  // TODO(progress): read from GET /v1/usage/daily and dailyProgress.
                  Text('0 of 10 minutes', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    backgroundColor: AppColors.border,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/prepare/emma'),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Start Speaking'),
          ),
          const SizedBox(height: 24),
          Text('Recommended tutor', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: TutorAvatar(tutor: emma),
              title: Text(emma.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(emma.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/tutors'),
            ),
          ),
        ],
      ),
    );
  }
}
