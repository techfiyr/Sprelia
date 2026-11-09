import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_selection_tile.dart';
import '../../../l10n/l10n.dart';
import '../../profile/data/learning_preferences.dart';
import '../languages.dart';
import '../onboarding_controller.dart';
import '../onboarding_labels.dart';

/// Renders the question for [step].
class OnboardingQuestion extends StatelessWidget {
  const OnboardingQuestion({super.key, required this.step, required this.state, required this.controller});

  final OnboardingStep step;
  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = state.preferences;
    return switch (step) {
      OnboardingStep.interfaceLanguage => _QuestionLayout(
          title: l10n.onboardingInterfaceLanguageTitle,
          subtitle: l10n.onboardingInterfaceLanguageSubtitle,
          footer: l10n.onboardingMoreLanguagesSoon,
          children: [
            for (final lang in interfaceLanguages())
              AppSelectionTile(
                title: lang.nativeName,
                subtitle: lang.englishName == lang.nativeName ? null : lang.englishName,
                selected: p.interfaceLanguage == lang.code,
                onTap: () => controller.setInterfaceLanguage(lang.code),
              ),
          ],
        ),
      OnboardingStep.nativeLanguage => _NativeLanguageQuestion(selected: p.nativeLanguage, onSelect: controller.setNativeLanguage),
      OnboardingStep.goals => _QuestionLayout(
          title: l10n.onboardingGoalsTitle,
          subtitle: l10n.onboardingGoalsSubtitle,
          children: [
            for (final goal in LearningGoal.values)
              AppSelectionTile(
                title: context.goalLabel(goal),
                subtitle: context.goalDescription(goal),
                multiSelect: true,
                selected: p.goals.contains(goal),
                onTap: () => controller.toggleGoal(goal),
              ),
          ],
        ),
      OnboardingStep.level => _QuestionLayout(
          title: l10n.onboardingLevelTitle,
          subtitle: l10n.onboardingLevelSubtitle,
          children: [
            for (final level in EnglishLevel.values)
              AppSelectionTile(
                title: context.levelLabel(level),
                subtitle: context.levelDescription(level),
                selected: p.level == level,
                onTap: () => controller.setLevel(level),
              ),
          ],
        ),
      OnboardingStep.dailyGoal => _QuestionLayout(
          title: l10n.onboardingDailyGoalTitle,
          subtitle: l10n.onboardingDailyGoalSubtitle,
          children: [
            for (final minutes in dailyGoalOptions)
              AppSelectionTile(
                title: l10n.dailyGoalMinutes(minutes),
                subtitle: context.dailyGoalHint(minutes),
                selected: p.dailyGoalMinutes == minutes,
                onTap: () => controller.setDailyGoal(minutes),
              ),
          ],
        ),
      OnboardingStep.accent => _QuestionLayout(
          title: l10n.onboardingAccentTitle,
          subtitle: l10n.onboardingAccentSubtitle,
          children: [
            for (final accent in AccentPreference.values)
              AppSelectionTile(
                title: context.accentLabel(accent),
                selected: p.accent == accent,
                onTap: () => controller.setAccent(accent),
              ),
          ],
        ),
      OnboardingStep.plan => const SizedBox.shrink(),
    };
  }
}

class _QuestionLayout extends StatelessWidget {
  const _QuestionLayout({required this.title, required this.subtitle, required this.children, this.footer, this.header});

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? footer;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      children: [
        Semantics(header: true, child: Text(title, style: context.textStyles.headlineSmall)),
        Gap.sm,
        Text(subtitle, style: context.textStyles.bodyLarge?.copyWith(color: context.palette.textSecondary)),
        Gap.xl,
        if (header != null) ...[header!, Gap.md],
        for (final child in children) ...[child, Gap.md],
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(footer!, style: context.textStyles.bodyMedium?.copyWith(color: context.palette.textSecondary)),
          ),
      ],
    );
  }
}

class _NativeLanguageQuestion extends StatefulWidget {
  const _NativeLanguageQuestion({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  State<_NativeLanguageQuestion> createState() => _NativeLanguageQuestionState();
}

class _NativeLanguageQuestionState extends State<_NativeLanguageQuestion> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = nativeLanguages.where((l) => l.matches(_query)).toList();
    return _QuestionLayout(
      title: l10n.onboardingNativeLanguageTitle,
      subtitle: l10n.onboardingNativeLanguageSubtitle,
      header: TextField(
        key: const ValueKey('native-language-search'),
        decoration: InputDecoration(
          hintText: l10n.onboardingSearchLanguages,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _query = v),
      ),
      footer: matches.isEmpty ? l10n.onboardingNoLanguageMatch : null,
      children: [
        for (final lang in matches)
          AppSelectionTile(
            title: lang.nativeName,
            subtitle: lang.englishName == lang.nativeName ? null : lang.englishName,
            selected: widget.selected == lang.code,
            onTap: () => widget.onSelect(lang.code),
          ),
      ],
    );
  }
}
