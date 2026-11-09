import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'premium_services.dart';

/// Premium paywall (APP_FLOW §16). Prices shown are the documented test hypotheses, clearly marked
/// as not final. Purchasing is disabled until store products and RevenueCat are configured.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final purchases = ref.watch(purchaseServiceProvider);
    final subscription = ref.watch(subscriptionProvider).value;

    Future<void> run(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
        ref.invalidate(subscriptionProvider);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(l10n.premiumHeadline, style: text.headlineSmall),
          Gap.md,
          if (subscription?.isPremium ?? false) ...[
            AppCard(tone: AppCardTone.tinted, child: Text(l10n.premiumActive, style: text.titleMedium)),
            Gap.lg,
          ],
          for (final benefit in [
            l10n.premiumBenefitTime,
            l10n.premiumBenefitScenarios,
            l10n.premiumBenefitFeedback,
            l10n.premiumBenefitHistory,
            l10n.premiumBenefitNoAds,
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_outline_rounded, color: context.colors.primary),
              title: Text(benefit),
            ),
          Gap.lg,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.premiumMonthly, style: text.titleMedium),
                Text(l10n.premiumAnnual, style: text.titleMedium),
                Gap.xs,
                Text(l10n.premiumPricesNotFinal, style: text.bodySmall),
              ],
            ),
          ),
          Gap.lg,
          if (!purchases.available) ...[
            Text(l10n.premiumUnavailable, textAlign: TextAlign.center, style: text.bodyMedium),
            Gap.md,
          ],
          AppButton(
            key: const ValueKey('paywall-subscribe'),
            label: l10n.premiumSubscribe,
            onPressed: purchases.available && !(subscription?.isPremium ?? false) ? () => run(() => purchases.purchase('monthly')) : null,
          ),
          Gap.sm,
          AppButton.text(
            key: const ValueKey('paywall-restore'),
            label: l10n.premiumRestore,
            expand: true,
            onPressed: purchases.available ? () => run(purchases.restore) : null,
          ),
          Gap.lg,
          Text(l10n.premiumManageNote, style: text.bodySmall),
        ],
      ),
    );
  }
}
