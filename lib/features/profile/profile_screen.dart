import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../account/delete_account_flow.dart';
import '../onboarding/onboarding_labels.dart';
import 'data/learning_preferences.dart';

/// Profile (APP_FLOW §17): read-only preferences, sign-out and account deletion
/// (Phase 3). Editing, subscription and privacy controls follow later.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final session = ref.watch(sessionProvider).value;
    if (session is! SignedIn) return const Scaffold(body: AppLoadingView());
    final profile = session.profile;
    final p = profile.preferences;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          AppCard(
            child: Row(
              children: [
                Icon(Icons.account_circle_outlined, size: 40, color: context.colors.primary),
                Gap.lg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.displayName != null) Text(profile.displayName!, style: text.titleMedium),
                      Text(profile.email ?? session.user.email ?? '', style: text.bodyMedium),
                      Text(profile.timezone, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap.xl,
          Text(l10n.profileLearningPreferences, style: text.titleMedium),
          Gap.sm,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pref(l10n.planGoals, LearningGoal.values.where(p.goals.contains).map(context.goalLabel).join(', ')),
                if (p.level != null) _Pref(l10n.planLevel, context.levelLabel(p.level!)),
                if (p.dailyGoalMinutes != null) _Pref(l10n.planDailyTarget, l10n.dailyGoalMinutes(p.dailyGoalMinutes!)),
                if (p.accent != null) _Pref(l10n.profileAccent, context.accentLabel(p.accent!)),
                if (p.nativeLanguage != null) _Pref(l10n.profileNativeLanguage, context.languageName(p.nativeLanguage)),
              ],
            ),
          ),
          Gap.xl,
          AppButton.secondary(
            key: const ValueKey('profile-sign-out'),
            label: l10n.profileSignOut,
            icon: Icons.logout_rounded,
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          Gap.xl,
          Text(l10n.profileAccountSection, style: text.titleMedium),
          Gap.sm,
          AppButton.destructive(
            key: const ValueKey('profile-delete-account'),
            label: l10n.profileDeleteAccount,
            icon: Icons.delete_forever_outlined,
            onPressed: () => runDeleteAccountFlow(context, ref, session.user),
          ),
          Gap.xl,
        ],
      ),
    );
  }
}

class _Pref extends StatelessWidget {
  const _Pref(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textStyles.bodySmall),
            Text(value, style: context.textStyles.titleSmall),
          ],
        ),
      );
}
