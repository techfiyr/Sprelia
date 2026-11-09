import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding/app_brand.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
              Gap.xl,
              Text(AppBrand.tagline, style: text.headlineMedium),
              Gap.md,
              Text(AppBrand.supportingText, style: text.bodyLarge?.copyWith(color: context.palette.textSecondary)),
              const Spacer(flex: 3),
              // Prototype: Firebase Auth (Google / email) arrives in Phase 4.
              AppButton(label: 'Get Started', onPressed: () => context.go(AppRoutes.home)),
              Gap.md,
              // TODO(onboarding): screens 1–8 (languages, goals, level, daily goal, accent, plan, account).
              AppButton.secondary(label: 'Sign In', onPressed: () => context.go(AppRoutes.home)),
            ],
          ),
        ),
      ),
    );
  }
}
