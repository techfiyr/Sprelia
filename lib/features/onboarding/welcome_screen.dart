import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/branding/app_brand.dart';
import '../../core/branding/brand_art.dart';
import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../auth/google_sign_in_button.dart';
import '../guest/guest_trial.dart';
import '../premium/ad_banner.dart';

/// Welcome (APP_FLOW §3): Continue with Google and Continue with Email. Google is
/// disabled (with a note) until the provider is configured; guest mode is
/// intentionally not offered.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textStyles;
    final signInAvailable = ref.watch(appConfigProvider).firebase != null;
    final googleAvailable = ref.watch(accountAuthProvider).googleSignInAvailable;
    final lessonDone = ref.watch(guestLessonDoneProvider);
    return Scaffold(
      backgroundColor: BrandPalette.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.xl * 2),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: BrandLogo(size: 44, showWordmark: true)),
                    const Spacer(),
                    const Center(child: TutorMascot(size: 230)),
                    Gap.lg,
                    Semantics(
                      header: true,
                      child: Text(
                        AppBrand.headline,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(color: BrandPalette.plumDeep, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Gap.sm,
                    Text(
                      AppBrand.tagline,
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(color: BrandPalette.coralText, fontWeight: FontWeight.w700),
                    ),
                    Gap.sm,
                    Text(
                      AppBrand.supportingText,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(color: context.palette.textSecondary),
                    ),
                    const Spacer(),
                    if (!lessonDone) ...[
                      AppButton(
                        key: const ValueKey('welcome-free-lesson'),
                        label: 'Try a free lesson',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => context.push(AppRoutes.guestLesson),
                      ),
                      Gap.sm,
                      Text(
                        'No account needed. Takes about two minutes.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                      Gap.md,
                      AppButton.secondary(
                        key: const ValueKey('welcome-email'),
                        label: 'Sign in or create account',
                        icon: Icons.mail_outline_rounded,
                        onPressed: signInAvailable ? () => context.push(AppRoutes.signIn) : null,
                      ),
                    ] else ...[
                      AppCard(
                        tone: AppCardTone.tinted,
                        child: Text(
                          'You finished your free lesson. Create an account to keep going. Full access needs a Hermione subscription.',
                          style: text.bodyMedium,
                        ),
                      ),
                      Gap.md,
                      if (signInAvailable) ...[
                        const GoogleSignInButton(),
                        if (!googleAvailable) ...[
                          Gap.xs,
                          Text(context.l10n.authGoogleUnavailable, textAlign: TextAlign.center, style: text.bodySmall),
                        ],
                        Gap.md,
                      ],
                      AppButton(
                        key: const ValueKey('welcome-email'),
                        label: context.l10n.welcomeContinueWithEmail,
                        icon: Icons.mail_outline_rounded,
                        onPressed: signInAvailable ? () => context.push(AppRoutes.signIn) : null,
                      ),
                    ],
                    if (!signInAvailable) ...[
                      Gap.md,
                      Text(
                        context.l10n.welcomeSignInUnavailable,
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdBannerArea(),
    );
  }
}
