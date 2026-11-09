import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/routing/app_routes.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../account/delete_account_flow.dart';
import '../onboarding/onboarding_labels.dart';
import '../practice/data/catalog_repository.dart';
import 'data/learning_preferences.dart';
import 'data/profile_repository.dart';
import 'preference_editor_screen.dart';

/// Profile and settings (APP_FLOW §17): learning preferences, display name, time zone,
/// preferred tutor, reminders, data export, sign-out and account deletion.
/// Subscription management arrives with Premium (Phase 9).
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
    final tutors = ref.watch(tutorsProvider).value ?? const [];
    final tutorName = tutors.where((t) => t.id == profile.preferredTutorId).firstOrNull?.name;

    void edit(PreferenceField f) => context.push(AppRoutes.profileEdit(f.slug));

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
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Section(l10n.profileLearningPreferences),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(
                  key: const ValueKey('profile-edit-goals'),
                  label: l10n.planGoals,
                  value: LearningGoal.values.where(p.goals.contains).map(context.goalLabel).join(', '),
                  onTap: () => edit(PreferenceField.goals),
                ),
                _Row(
                  key: const ValueKey('profile-edit-level'),
                  label: l10n.planLevel,
                  value: p.level == null ? l10n.commonNotSet : context.levelLabel(p.level!),
                  onTap: () => edit(PreferenceField.level),
                ),
                _Row(
                  key: const ValueKey('profile-edit-daily-goal'),
                  label: l10n.planDailyTarget,
                  value: p.dailyGoalMinutes == null ? l10n.commonNotSet : l10n.dailyGoalMinutes(p.dailyGoalMinutes!),
                  onTap: () => edit(PreferenceField.dailyGoal),
                ),
                _Row(
                  key: const ValueKey('profile-edit-accent'),
                  label: l10n.profileAccent,
                  value: p.accent == null ? l10n.commonNotSet : context.accentLabel(p.accent!),
                  onTap: () => edit(PreferenceField.accent),
                ),
                _Row(
                  key: const ValueKey('profile-edit-native-language'),
                  label: l10n.profileNativeLanguage,
                  value: p.nativeLanguage == null ? l10n.commonNotSet : context.languageName(p.nativeLanguage),
                  onTap: () => edit(PreferenceField.nativeLanguage),
                ),
              ],
            ),
          ),
          _Section(l10n.profilePracticeSection),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(
                  key: const ValueKey('profile-preferred-tutor'),
                  label: l10n.profilePreferredTutor,
                  value: tutorName ?? l10n.profileTutorAutomatic,
                  onTap: () => _chooseTutor(context, ref, profile.preferredTutorId),
                ),
                SwitchListTile(
                  key: const ValueKey('profile-reminders'),
                  title: Text(l10n.profileReminders),
                  subtitle: Text(l10n.profileRemindersNote),
                  value: profile.practiceReminders,
                  onChanged: (v) => _update(context, ref, ProfileUpdate(practiceReminders: v)),
                ),
              ],
            ),
          ),
          _Section(l10n.profileAccountSection),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(
                  key: const ValueKey('profile-display-name'),
                  label: l10n.profileDisplayName,
                  value: profile.displayName ?? l10n.commonNotSet,
                  onTap: () => _editDisplayName(context, ref, profile.displayName),
                ),
                _Row(
                  key: const ValueKey('profile-time-zone'),
                  label: l10n.profileTimeZone,
                  value: profile.timezone,
                  onTap: () => _editTimeZone(context, ref, profile.timezone),
                ),
              ],
            ),
          ),
          _Section(l10n.profilePrivacySection),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('profile-export'),
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.profileExportData),
                  onTap: () => _export(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(l10n.profilePolicies, style: text.bodyMedium),
                ),
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
          Gap.md,
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

/// Sends a profile patch, refreshes the session and dashboard, and reports the outcome.
Future<bool> _update(BuildContext context, WidgetRef ref, ProfileUpdate update) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  try {
    await ref.read(profileRepositoryProvider).updateProfile(update);
    ref.invalidate(dashboardProvider);
    await ref.read(sessionProvider.notifier).reload();
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    return true;
  } catch (e, st) {
    final failure = AppFailure.from(e);
    if (failure is UnexpectedFailure) ref.read(errorReporterProvider).report(e, st, reason: 'Profile update failed');
    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    return false;
  }
}

Future<void> _editDisplayName(BuildContext context, WidgetRef ref, String? current) async {
  final value = await showDialog<String>(context: context, builder: (_) => _DisplayNameDialog(initial: current ?? ''));
  if (value == null || !context.mounted) return;
  final trimmed = value.trim();
  if (trimmed == (current ?? '')) return;
  await _update(context, ref, trimmed.isEmpty ? const ProfileUpdate(clearDisplayName: true) : ProfileUpdate(displayName: trimmed));
}

Future<void> _editTimeZone(BuildContext context, WidgetRef ref, String current) async {
  final l10n = context.l10n;
  final device = await ref.read(deviceTimeZoneProvider)();
  if (!context.mounted) return;
  final use = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.profileTimeZone),
      content: Text('$current\n\n${l10n.profileTimeZoneNote}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        if (device != current)
          TextButton(
            key: const ValueKey('profile-use-device-time-zone'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.profileUseDeviceTimeZone(device)),
          ),
      ],
    ),
  );
  if (use == true && context.mounted) await _update(context, ref, ProfileUpdate(timezone: device));
}

Future<void> _chooseTutor(BuildContext context, WidgetRef ref, String? current) async {
  final l10n = context.l10n;
  final tutors = await ref.read(tutorsProvider.future).catchError((_) => <Never>[]);
  if (!context.mounted) return;
  // '' = automatic; null = dismissed.
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: RadioGroup<String>(
        groupValue: current ?? '',
        onChanged: (v) => Navigator.pop(context, v),
        child: ListView(
          shrinkWrap: true,
          children: [
            RadioListTile<String>(
              key: const ValueKey('tutor-choice-automatic'),
              title: Text(l10n.profileTutorAutomatic),
              value: '',
            ),
            for (final t in tutors)
              RadioListTile<String>(
                key: ValueKey('tutor-choice-${t.id}'),
                title: Text(t.name),
                subtitle: Text(t.title),
                value: t.id,
              ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || choice == (current ?? '') || !context.mounted) return;
  await _update(context, ref, choice.isEmpty ? const ProfileUpdate(clearPreferredTutor: true) : ProfileUpdate(preferredTutorId: choice));
}

Future<void> _export(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  try {
    final json = await ref.read(profileRepositoryProvider).exportData();
    await Clipboard.setData(ClipboardData(text: json));
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileExportDone)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
  }
}

class _DisplayNameDialog extends StatefulWidget {
  const _DisplayNameDialog({required this.initial});

  final String initial;

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.profileDisplayName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            key: const ValueKey('display-name-field'),
            label: l10n.profileDisplayName,
            controller: _controller,
            maxLength: 60,
            autofocus: true,
            autofillHints: const [AutofillHints.name],
            onSubmitted: (_) => Navigator.pop(context, _controller.text),
          ),
          Text(l10n.profileDisplayNameHint, style: context.textStyles.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        TextButton(
          key: const ValueKey('display-name-save'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
        child: Text(title, style: context.textStyles.titleMedium),
      );
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label, style: context.textStyles.bodySmall),
        subtitle: Text(value, style: context.textStyles.titleSmall),
        trailing: Icon(Icons.chevron_right_rounded, semanticLabel: context.l10n.commonEdit),
        onTap: onTap,
      );
}
