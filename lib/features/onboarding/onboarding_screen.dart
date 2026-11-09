import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'onboarding_controller.dart';
import 'steps/onboarding_steps.dart';
import 'steps/plan_step.dart';

/// Onboarding (APP_FLOW §5): one question per screen, a clear progress
/// indicator, Back and Continue. Progress is saved after every change.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    if (state.step == OnboardingStep.plan) {
      return PlanStep(state: state, onStart: controller.finish);
    }

    final total = onboardingQuestions.length;
    final index = state.questionIndex;
    final isLast = state.step == onboardingQuestions.last;

    return PopScope(
      canPop: state.isFirst,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: state.isFirst
              ? null
              : IconButton(
                  tooltip: context.l10n.actionBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: state.submitting ? null : controller.back,
                ),
          automaticallyImplyLeading: false,
          title: Text(context.l10n.stepProgress(index + 1, total), style: context.textStyles.labelLarge),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Semantics(
              label: context.l10n.stepProgress(index + 1, total),
              child: LinearProgressIndicator(value: (index + 1) / total, minHeight: 4),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(state.step),
                    child: OnboardingQuestion(step: state.step, state: state, controller: controller),
                  ),
                ),
              ),
              if (state.failure != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    state.failure!.message,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(color: context.colors.error),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton(
                  key: const ValueKey('onboarding-continue'),
                  label: isLast ? context.l10n.onboardingCreatePlan : context.l10n.actionContinue,
                  isLoading: state.submitting,
                  onPressed: state.canContinue ? controller.next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
