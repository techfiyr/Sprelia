import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/app_assets.dart';
import '../../core/branding/app_brand.dart';
import '../../core/branding/brand_art.dart';
import '../../core/errors/app_failure.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';

/// Splash (APP_FLOW §2): shown while the session loads. On failure it offers
/// a retry and sign-out instead of an endless spinner.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      backgroundColor: BrandPalette.cream,
      body: SafeArea(
        child: session.hasError && !session.isLoading
            ? Column(
                children: [
                  Expanded(
                    child: AppErrorState(
                      failure: AppFailure.from(session.error!),
                      onRetry: () => ref.invalidate(sessionProvider),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: AppButton.text(
                      label: context.l10n.profileSignOut,
                      onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SplashMark(),
                    Gap.lg,
                    AppLoadingIndicator(semanticLabel: context.l10n.splashLoading),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The looping Hermione mascot animation. The static [BrandLogo] is the fallback when the asset is
/// unavailable, fails to decode, or the system asks for reduced motion.
class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    const logo = BrandLogo(size: 72);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animation = AppAssets.splashWave;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (animation.isUsable && !reduceMotion)
          Semantics(
            label: '${AppBrand.name} tutor waving',
            image: true,
            child: Image.asset(
              animation.path,
              key: const ValueKey('splash-animation'),
              width: 200,
              height: 200,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => logo,
            ),
          )
        else
          logo,
        if (animation.isUsable && !reduceMotion) ...[
          Gap.sm,
          Text(
            AppBrand.name,
            style: context.textStyles.headlineMedium?.copyWith(color: BrandPalette.plum, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}
