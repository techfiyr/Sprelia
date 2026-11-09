import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../onboarding/languages.dart';
import '../onboarding/onboarding_labels.dart';
import 'data/learning_preferences.dart';
import 'data/profile_repository.dart';

/// Learning preferences that can be edited after onboarding (APP_FLOW §17).
enum PreferenceField {
  nativeLanguage('native-language'),
  goals('goals'),
  level('level'),
  dailyGoal('daily-goal'),
  accent('accent');

  const PreferenceField(this.slug);
  final String slug;

  static PreferenceField? fromSlug(String? s) => values.where((f) => f.slug == s).firstOrNull;
}

/// Edits one learning preference with the same options as onboarding, then saves it
/// with `PATCH /me/preferences` (validated by the server) and refreshes the session.
class PreferenceEditorScreen extends ConsumerStatefulWidget {
  const PreferenceEditorScreen({super.key, required this.field});

  final PreferenceField field;

  @override
  ConsumerState<PreferenceEditorScreen> createState() => _PreferenceEditorScreenState();
}

class _PreferenceEditorScreenState extends ConsumerState<PreferenceEditorScreen> {
  late LearningPreferences _original;
  late LearningPreferences _value;
  String _query = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider).value;
    _original = session is SignedIn ? session.profile.preferences : const LearningPreferences();
    _value = _original;
  }

  /// Only the edited field is sent.
  LearningPreferences get _patch => switch (widget.field) {
        PreferenceField.nativeLanguage => LearningPreferences(nativeLanguage: _value.nativeLanguage),
        PreferenceField.goals => LearningPreferences(goals: _value.goals),
        PreferenceField.level => LearningPreferences(level: _value.level),
        PreferenceField.dailyGoal => LearningPreferences(dailyGoalMinutes: _value.dailyGoalMinutes),
        PreferenceField.accent => LearningPreferences(accent: _value.accent),
      };

  bool get _changed => _patch.toJson().toString() != _originalPatch.toString();

  Map<String, Object?> get _originalPatch => switch (widget.field) {
        PreferenceField.nativeLanguage => LearningPreferences(nativeLanguage: _original.nativeLanguage).toJson(),
        PreferenceField.goals => LearningPreferences(goals: _original.goals).toJson(),
        PreferenceField.level => LearningPreferences(level: _original.level).toJson(),
        PreferenceField.dailyGoal => LearningPreferences(dailyGoalMinutes: _original.dailyGoalMinutes).toJson(),
        PreferenceField.accent => LearningPreferences(accent: _original.accent).toJson(),
      };

  bool get _valid => _patch.toJson().isNotEmpty;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final l10n = context.l10n;
    try {
      await ref.read(profileRepositoryProvider).updatePreferences(_patch);
      ref.invalidate(dashboardProvider);
      await ref.read(sessionProvider.notifier).reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final (title, subtitle) = switch (widget.field) {
      PreferenceField.nativeLanguage => (l10n.onboardingNativeLanguageTitle, l10n.onboardingNativeLanguageSubtitle),
      PreferenceField.goals => (l10n.onboardingGoalsTitle, l10n.onboardingGoalsSubtitle),
      PreferenceField.level => (l10n.onboardingLevelTitle, l10n.onboardingLevelSubtitle),
      PreferenceField.dailyGoal => (l10n.onboardingDailyGoalTitle, l10n.onboardingDailyGoalSubtitle),
      PreferenceField.accent => (l10n.onboardingAccentTitle, l10n.onboardingAccentSubtitle),
    };

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                children: [
                  Text(title, style: text.headlineSmall),
                  Gap.xs,
                  Text(subtitle, style: text.bodyMedium?.copyWith(color: context.palette.textSecondary)),
                  Gap.lg,
                  ..._options(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(_error!, style: text.bodyMedium?.copyWith(color: context.colors.error)),
                    ),
                    Gap.md,
                  ],
                  AppButton(
                    key: const ValueKey('preference-save'),
                    label: l10n.commonSave,
                    isLoading: _saving,
                    onPressed: _valid && _changed && !_saving ? _save : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _options(BuildContext context) {
    final l10n = context.l10n;
    final tiles = <Widget>[];
    void add(Widget w) => tiles
      ..add(w)
      ..add(Gap.sm);
    switch (widget.field) {
      case PreferenceField.nativeLanguage:
        add(TextField(
          key: const ValueKey('preference-language-search'),
          decoration: InputDecoration(hintText: l10n.onboardingSearchLanguages, prefixIcon: const Icon(Icons.search_rounded)),
          onChanged: (v) => setState(() => _query = v),
        ));
        final matches = nativeLanguages.where((l) => l.matches(_query)).toList();
        if (matches.isEmpty) add(Text(l10n.onboardingNoLanguageMatch));
        for (final lang in matches) {
          add(AppSelectionTile(
            title: lang.nativeName,
            subtitle: lang.englishName == lang.nativeName ? null : lang.englishName,
            selected: _value.nativeLanguage == lang.code,
            onTap: () => setState(() => _value = _value.copyWith(nativeLanguage: lang.code)),
          ));
        }
      case PreferenceField.goals:
        for (final goal in LearningGoal.values) {
          add(AppSelectionTile(
            title: context.goalLabel(goal),
            subtitle: context.goalDescription(goal),
            multiSelect: true,
            selected: _value.goals.contains(goal),
            onTap: () => setState(() {
              final goals = {..._value.goals};
              goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
              _value = LearningPreferences(
                interfaceLanguage: _value.interfaceLanguage,
                nativeLanguage: _value.nativeLanguage,
                goals: goals,
                level: _value.level,
                dailyGoalMinutes: _value.dailyGoalMinutes,
                accent: _value.accent,
              );
            }),
          ));
        }
      case PreferenceField.level:
        for (final level in EnglishLevel.values) {
          add(AppSelectionTile(
            title: context.levelLabel(level),
            subtitle: context.levelDescription(level),
            selected: _value.level == level,
            onTap: () => setState(() => _value = _value.copyWith(level: level)),
          ));
        }
      case PreferenceField.dailyGoal:
        for (final minutes in dailyGoalOptions) {
          add(AppSelectionTile(
            title: l10n.dailyGoalMinutes(minutes),
            subtitle: context.dailyGoalHint(minutes),
            selected: _value.dailyGoalMinutes == minutes,
            onTap: () => setState(() => _value = _value.copyWith(dailyGoalMinutes: minutes)),
          ));
        }
      case PreferenceField.accent:
        for (final accent in AccentPreference.values) {
          add(AppSelectionTile(
            title: context.accentLabel(accent),
            selected: _value.accent == accent,
            onTap: () => setState(() => _value = _value.copyWith(accent: accent)),
          ));
        }
    }
    return tiles;
  }
}
