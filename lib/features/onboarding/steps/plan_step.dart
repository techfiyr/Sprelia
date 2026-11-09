import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../practice/data/catalog_repository.dart';
import '../../profile/data/learning_preferences.dart';
import '../../tutors/tutor_avatar.dart';
import '../onboarding_controller.dart';
import '../onboarding_labels.dart';

/// Personalized learning plan (APP_FLOW §5, screen 7), built from the
/// server's recommendation after onboarding is saved.
class PlanStep extends ConsumerStatefulWidget {
  const PlanStep({super.key, required this.state, required this.onStart});

  final OnboardingState state;
  final Future<void> Function() onStart;

  @override
  ConsumerState<PlanStep> createState() => _PlanStepState();
}

class _PlanStepState extends ConsumerState<PlanStep> {
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await widget.onStart();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final prefs = widget.state.preferences;
    final plan = widget.state.plan!;
    final tutor = ref.watch(tutorByIdProvider(plan.tutorId));
    final categories = ref.watch(practiceCategoriesProvider).value ?? const [];
    final suggested = [
      for (final id in plan.categoryIds) ...categories.where((c) => c.id == id),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Gap.lg,
                  Icon(Icons.celebration_outlined, size: 40, color: context.colors.primary),
                  Gap.lg,
                  Semantics(header: true, child: Text(l10n.planTitle, style: text.headlineSmall)),
                  Gap.sm,
                  Text(l10n.planSubtitle, style: text.bodyLarge?.copyWith(color: context.palette.textSecondary)),
                  Gap.xl,
                  _PlanRow(
                    icon: Icons.flag_outlined,
                    label: l10n.planGoals,
                    value: LearningGoal.values.where(prefs.goals.contains).map(context.goalLabel).join(', '),
                  ),
                  _PlanRow(icon: Icons.trending_up_rounded, label: l10n.planLevel, value: context.levelLabel(prefs.level!)),
                  _PlanRow(
                    icon: Icons.timer_outlined,
                    label: l10n.planDailyTarget,
                    value: l10n.dailyGoalMinutes(prefs.dailyGoalMinutes!),
                  ),
                  if (suggested.isNotEmpty)
                    _PlanRow(
                      icon: Icons.forum_outlined,
                      label: l10n.planSuggestedPractice,
                      value: suggested.map((c) => c.title).join(', '),
                    ),
                  Gap.lg,
                  Text(l10n.planRecommendedTutor, style: text.titleMedium),
                  Gap.sm,
                  AppCard(
                    tone: AppCardTone.tinted,
                    child: Row(
                      children: [
                        TutorAvatar(tutor: tutor, size: 52),
                        Gap.lg,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tutor.name, style: text.titleMedium?.copyWith(color: context.palette.primaryDark)),
                              if (tutor.title.isNotEmpty) Text(tutor.title, style: text.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                key: const ValueKey('plan-start'),
                label: l10n.planStartPractising,
                isLoading: _starting,
                onPressed: _start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: context.colors.primary),
          Gap.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textStyles.bodySmall),
                Text(value, style: context.textStyles.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
