import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(progress): speaking minutes, conversations, streak, vocabulary, mistakes.
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(child: Text('Your progress will appear here after your first conversations.')),
    );
  }
}
