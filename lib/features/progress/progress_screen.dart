import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(progress): speaking minutes, conversations, streak, vocabulary, mistakes.
    // Only real, server-derived statistics may be shown (BRAND §7).
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const AppEmptyState(
        icon: Icons.insights_outlined,
        title: 'No progress yet',
        message: 'Your progress will appear here after your first conversations.',
      ),
    );
  }
}
