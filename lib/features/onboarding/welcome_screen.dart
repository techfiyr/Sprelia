import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 28),
              Text('Speak English with confidence',
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.15)),
              const SizedBox(height: 12),
              Text(
                'Have real-time voice conversations with friendly AI tutors and get '
                'personal feedback after every session.',
                style: text.bodyLarge?.copyWith(color: AppColors.inkMuted),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              // TODO(onboarding): screens 3–10 (languages, goals, level, daily goal, accent, plan, account).
              OutlinedButton(onPressed: () => context.go('/home'), child: const Text('Sign In')),
            ],
          ),
        ),
      ),
    );
  }
}
