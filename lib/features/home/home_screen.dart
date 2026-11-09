import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
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
    final text = context.textStyles;
    final secondary = context.palette.textSecondary;
    final emma = tutorById('emma');
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          Text(_greeting(), style: text.headlineSmall),
          Gap.xs,
          Text('Ready to improve your English?', style: text.bodyLarge?.copyWith(color: secondary)),
          Gap.xl,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's goal", style: text.labelLarge?.copyWith(color: secondary)),
                const SizedBox(height: 6),
                // TODO(progress): read from the server-authoritative daily usage endpoint.
                Text('0 of 10 minutes', style: text.titleLarge),
                const SizedBox(height: 10),
                const LinearProgressIndicator(value: 0, minHeight: 6, borderRadius: BorderRadius.all(Radius.circular(3))),
              ],
            ),
          ),
          Gap.lg,
          AppButton(
            label: 'Start Speaking',
            icon: Icons.mic_rounded,
            onPressed: () => context.push(AppRoutes.prepare(emma.id)),
          ),
          Gap.xl,
          Text('Recommended tutor', style: text.titleMedium),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            onTap: () => context.push(AppRoutes.tutors),
            child: Row(
              children: [
                TutorAvatar(tutor: emma),
                Gap.lg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emma.name, style: text.titleSmall),
                      Text(emma.title, style: text.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
