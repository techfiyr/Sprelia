import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'entitlement.dart';
import 'premium_services.dart';

/// The persistent bottom banner area for non-subscribers (guests and signed-in users without an
/// active subscription). Active subscribers never see it; nothing shows while the entitlement is
/// still being verified, so a subscriber never sees an ad flash.
///
/// Honesty rules: no ad is faked. A real banner needs the AdMob SDK, the AdMob app ID, the banner
/// ad unit ID and the consent flow (owner action); until then the real build shows nothing at
/// all, and debug builds show a clearly labelled layout placeholder so the slot can be reviewed.
/// Policy: never during a conversation or on the paywall (`adAllowed`).
class AdBannerArea extends ConsumerWidget {
  const AdBannerArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    if (entitlement.isLoading || entitlement.hasError) return const SizedBox.shrink();
    final plan = entitlement.value == true ? Plan.premium : Plan.free;
    if (!adAllowed(plan, AdPlacement.bottomBanner)) return const SizedBox.shrink();

    final ads = ref.watch(adServiceProvider);
    if (ads.available) return SafeArea(top: false, child: ads.buildBanner(context));
    if (!kDebugMode) return const SizedBox.shrink();
    return const SafeArea(top: false, child: _DevAdPlaceholder());
  }
}

class _DevAdPlaceholder extends StatelessWidget {
  const _DevAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Ad space placeholder, development build only. Not a real ad.',
      child: Container(
        key: const ValueKey('ad-banner-placeholder'),
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.primaryLight,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: Text(
          'Ad space (development placeholder, not a real ad)',
          style: context.textStyles.bodySmall?.copyWith(color: palette.textSecondary),
        ),
      ),
    );
  }
}
