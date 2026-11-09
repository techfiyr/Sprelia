import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(profile): preferences, subscription, privacy controls, delete account, sign out.
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const AppEmptyState(
        icon: Icons.person_outline,
        title: 'Profile and settings',
        message: 'Profile and settings are coming soon.',
      ),
    );
  }
}
