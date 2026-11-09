import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../learn/data/learning_repository.dart';
import '../practice/data/catalog_repository.dart';

/// Progress tab (APP_FLOW §15). Only real, server-derived statistics are shown (BRAND §7).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: switch (ref.watch(progressProvider)) {
        AsyncData(:final value) when value.isEmpty => AppEmptyState(
            icon: Icons.insights_outlined,
            title: l10n.progressEmptyTitle,
            message: l10n.progressEmptyMessage,
          ),
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => ref.refresh(progressProvider.future),
            child: _ProgressBody(progress: value),
          ),
        AsyncError(:final error) => AppErrorState(failure: AppFailure.from(error), onRetry: () => ref.invalidate(progressProvider)),
        _ => const AppLoadingView(),
      },
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final tutors = ref.watch(tutorsProvider).value ?? const [];
    final locale = Localizations.localeOf(context).toLanguageTag();
    final week = progress.days.length > 7 ? progress.days.sublist(progress.days.length - 7) : progress.days;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeStreak(progress.streakDays), style: text.titleLarge),
              Gap.sm,
              Text(l10n.progressMinutes30(progress.totalSpeakingSeconds ~/ 60), style: text.bodyMedium),
              Text(l10n.progressSessions30(progress.totalSessions), style: text.bodyMedium),
            ],
          ),
        ),
        Gap.lg,
        Text(l10n.progressLast7Days, style: text.titleMedium),
        Gap.sm,
        AppCard(child: _WeekBars(days: week, locale: locale)),
        Gap.lg,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.progressMistakes(progress.mistakesOpen, progress.mistakesMastered), style: text.bodyMedium),
              Gap.xs,
              Text(l10n.progressVocabulary(progress.vocabularyTotal, progress.vocabularyLearned), style: text.bodyMedium),
            ],
          ),
        ),
        if (progress.recentSessions.isNotEmpty) ...[
          Gap.lg,
          Text(l10n.progressRecentSessions, style: text.titleMedium),
          Gap.sm,
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final s in progress.recentSessions)
                  ListTile(
                    key: ValueKey('recent-${s.id}'),
                    leading: const Icon(Icons.record_voice_over_outlined),
                    title: Text(tutors.where((t) => t.id == s.tutorId).firstOrNull?.name ?? s.tutorId),
                    subtitle: Text(DateFormat.yMMMd(locale).format(s.startedAt.toLocal())),
                    trailing: Text(l10n.progressSessionMinutes((s.billedSeconds / 60).ceil())),
                  ),
              ],
            ),
          ),
        ],
        Gap.xl,
      ],
    );
  }
}

/// Simple accessible bar chart: each bar has a spoken label with the day and minutes.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days, required this.locale});

  final List<ProgressDay> days;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxSeconds = days.fold<int>(0, (m, d) => d.speakingSeconds > m ? d.speakingSeconds : m);
    final palette = context.palette;
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Semantics(
                label: l10n.progressDayMinutes(DateFormat.EEEE(locale).format(DateTime.parse(d.date)), d.speakingSeconds ~/ 60),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: maxSeconds == 0 ? 0.02 : (d.speakingSeconds / maxSeconds).clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: d.speakingSeconds > 0 ? context.colors.primary : palette.border,
                              borderRadius: AppRadius.smallAll,
                            ),
                          ),
                        ),
                      ),
                      Gap.xs,
                      Text(DateFormat.E(locale).format(DateTime.parse(d.date)), style: context.textStyles.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
