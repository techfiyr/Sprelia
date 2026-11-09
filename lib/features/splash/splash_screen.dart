import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                    const BrandLogo(size: 72),
                    Gap.xl,
                    AppLoadingIndicator(semanticLabel: context.l10n.splashLoading),
                  ],
                ),
              ),
      ),
    );
  }
}
