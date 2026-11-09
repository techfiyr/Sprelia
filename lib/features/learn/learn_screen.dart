import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'data/learning_repository.dart';

/// Learn tab: Mistake Vault and Vocabulary (APP_FLOW §13–14), filled from validated post-session
/// feedback. Items can be marked mastered/learned.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.learnTitle),
          bottom: TabBar(tabs: [Tab(text: l10n.learnMistakeVault), Tab(text: l10n.learnVocabulary)]),
        ),
        body: const TabBarView(children: [_MistakeList(), _VocabularyList()]),
      ),
    );
  }
}

Future<void> _toggle(BuildContext context, WidgetRef ref, Future<void> Function() action, VoidCallback refresh) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    refresh();
    ref.invalidate(progressProvider);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
  }
}

class _MistakeList extends ConsumerWidget {
  const _MistakeList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final palette = context.palette;
    return switch (ref.watch(mistakesProvider)) {
      AsyncData(:final value) when value.isEmpty => AppEmptyState(
          icon: Icons.auto_fix_high_outlined,
          title: l10n.learnMistakeVault,
          message: l10n.learnMistakesEmpty,
        ),
      AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(mistakesProvider.future),
          child: ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: value.length,
            separatorBuilder: (_, _) => Gap.md,
            itemBuilder: (context, i) {
              final m = value[i];
              return Opacity(
                opacity: m.mastered ? 0.6 : 1,
                child: AppCard(
                  key: ValueKey('mistake-${m.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.original, style: text.bodyMedium?.copyWith(color: palette.danger, decoration: TextDecoration.lineThrough)),
                      Gap.xs,
                      Text(m.improved, style: text.bodyMedium?.copyWith(color: palette.successText, fontWeight: FontWeight.w600)),
                      Gap.sm,
                      Text(m.explanation, style: text.bodySmall),
                      CheckboxListTile(
                        key: ValueKey('mistake-mastered-${m.id}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(l10n.learnMastered),
                        value: m.mastered,
                        onChanged: (v) => _toggle(
                          context,
                          ref,
                          () => ref.read(learningRepositoryProvider).setMistakeMastered(m.id, v ?? false),
                          () => ref.invalidate(mistakesProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      AsyncError(:final error) => AppErrorState(failure: AppFailure.from(error), onRetry: () => ref.invalidate(mistakesProvider)),
      _ => const AppLoadingView(),
    };
  }
}

class _VocabularyList extends ConsumerWidget {
  const _VocabularyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    return switch (ref.watch(vocabularyProvider)) {
      AsyncData(:final value) when value.isEmpty => AppEmptyState(
          icon: Icons.style_outlined,
          title: l10n.learnVocabulary,
          message: l10n.learnVocabularyEmpty,
        ),
      AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(vocabularyProvider.future),
          child: ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: value.length,
            separatorBuilder: (_, _) => Gap.md,
            itemBuilder: (context, i) {
              final v = value[i];
              return AppCard(
                key: ValueKey('vocabulary-${v.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.term, style: text.titleMedium),
                    Gap.xs,
                    Text(v.meaning, style: text.bodyMedium),
                    if (v.example.isNotEmpty) ...[Gap.xs, Text('“${v.example}”', style: text.bodySmall)],
                    CheckboxListTile(
                      key: ValueKey('vocabulary-learned-${v.id}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l10n.learnLearned),
                      value: v.learned,
                      onChanged: (value) => _toggle(
                        context,
                        ref,
                        () => ref.read(learningRepositoryProvider).setVocabularyLearned(v.id, value ?? false),
                        () => ref.invalidate(vocabularyProvider),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      AsyncError(:final error) => AppErrorState(failure: AppFailure.from(error), onRetry: () => ref.invalidate(vocabularyProvider)),
      _ => const AppLoadingView(),
    };
  }
}
