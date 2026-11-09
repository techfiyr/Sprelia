import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../profile/data/profile_repository.dart';
import '../tutors/tutor_avatar.dart';
import 'data/catalog_repository.dart';

/// Conversation preparation (APP_FLOW §9): tutor, scenario, objective,
/// duration and remaining free time. No AI session is created here.
///
/// Phase 2: live voice sessions are not part of this phase. In development
/// builds the existing Emma prototype can still be launched; elsewhere the
/// start button explains that voice practice is coming soon.
class PrepareScreen extends ConsumerWidget {
  const PrepareScreen({super.key, required this.tutorId, this.scenarioId});

  final String tutorId;
  final String? scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final tutor = ref.watch(tutorByIdProvider(tutorId));
    final match = scenarioId == null ? null : ref.watch(scenarioByIdProvider(scenarioId!));
    final scenario = match?.$2;
    final remaining = ref.watch(dashboardProvider).value?.remainingFreeSeconds;
    final canStart = tutor.voiceAvailable && ref.watch(appConfigProvider).voicePrototypeEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepareTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(child: TutorAvatar(tutor: tutor, size: 96)),
                  Gap.lg,
                  Text(tutor.name, textAlign: TextAlign.center, style: text.headlineSmall),
                  if (tutor.title.isNotEmpty)
                    Text(tutor.title, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: context.palette.textSecondary)),
                  Center(
                    child: AppButton.text(
                      key: const ValueKey('prepare-change-tutor'),
                      label: l10n.prepareChangeTutor,
                      onPressed: () => context.pushReplacement(AppRoutes.tutorsFor(scenarioId: scenarioId)),
                    ),
                  ),
                  Gap.md,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scenario?.title ?? l10n.practiceFreeConversation, style: text.titleMedium),
                        if (scenario != null) ...[Gap.xs, Text(scenario.description, style: text.bodyMedium)],
                        Gap.lg,
                        Text(l10n.prepareObjectives, style: text.labelLarge),
                        Gap.xs,
                        for (final o in scenario?.objectives ?? [l10n.prepareFreeConversationObjective])
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_rounded, size: 18, color: context.colors.primary),
                                Gap.sm,
                                Expanded(child: Text(o, style: text.bodyMedium)),
                              ],
                            ),
                          ),
                        if (scenario != null && scenario.vocabulary.isNotEmpty) ...[
                          Gap.lg,
                          Text(l10n.prepareVocabulary, style: text.labelLarge),
                          Gap.sm,
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [for (final v in scenario.vocabulary) Chip(label: Text(v))],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Gap.md,
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: l10n.prepareDuration,
                    value: l10n.prepareMinutes(scenario?.estimatedMinutes ?? 5),
                  ),
                  if (remaining != null)
                    _InfoRow(icon: Icons.hourglass_bottom_rounded, label: l10n.prepareFreeTime, value: l10n.prepareMinutes(remaining ~/ 60)),
                  Gap.md,
                  AppCard(
                    tone: AppCardTone.tinted,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.prepareMicrophoneNote, style: text.bodySmall?.copyWith(color: context.palette.textPrimary)),
                        Gap.sm,
                        Text(l10n.preparePrivacyNote, style: text.bodySmall?.copyWith(color: context.palette.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (!canStart) ...[
                    Text(l10n.prepareVoiceComingSoon(tutor.name), textAlign: TextAlign.center, style: text.bodyMedium),
                    Gap.md,
                  ],
                  AppButton(
                    key: const ValueKey('prepare-start'),
                    label: l10n.prepareStart,
                    icon: Icons.mic_rounded,
                    onPressed: canStart ? () => context.pushReplacement(AppRoutes.conversation(tutor.id)) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final muted = context.palette.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          Gap.md,
          Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: muted))),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
  }
}
