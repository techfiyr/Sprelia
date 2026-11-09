import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

/// Learn tab: Mistake Vault and Vocabulary (APP_FLOW §13–14). Not built yet;
/// shows the specified empty states.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: const [
          _Section(
            icon: Icons.auto_fix_high_outlined,
            title: 'Mistake Vault',
            message: 'Great! No saved corrections yet. Your feedback will appear here after practice.',
          ),
          Gap.md,
          _Section(
            icon: Icons.style_outlined,
            title: 'Vocabulary',
            message: "You haven't saved any vocabulary yet. Start a conversation to discover useful new words.",
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary),
          Gap.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium),
                Gap.xs,
                Text(message, style: context.textStyles.bodyMedium?.copyWith(color: context.palette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
