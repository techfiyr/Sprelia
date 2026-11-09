import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/branding/app_brand.dart';
import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../auth/google_sign_in_button.dart';

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
    return Scaffold(
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
                    const Spacer(flex: 2),
                    const Align(alignment: Alignment.centerLeft, child: BrandLogo(showWordmark: true)),
                    Gap.xl,
                    Text(AppBrand.tagline, style: text.headlineMedium),
                    Gap.md,
                    Text(AppBrand.supportingText, style: text.bodyLarge?.copyWith(color: context.palette.textSecondary)),
                    const Spacer(flex: 3),
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
    );
  }
}
