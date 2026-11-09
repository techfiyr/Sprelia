import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/widgets/widgets.dart';

/// Practice tab. Scenario discovery (APP_FLOW §8) is not built yet; free
/// conversation with a tutor is available.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: AppEmptyState(
        icon: Icons.record_voice_over_outlined,
        title: 'Practice scenarios are coming soon',
        message: 'Job interviews, travel, small talk and more. For now, start a free conversation with a tutor.',
        actionLabel: 'Choose a tutor',
        onAction: () => context.push(AppRoutes.tutors),
      ),
    );
  }
}
