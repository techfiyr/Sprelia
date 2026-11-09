import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../practice/data/catalog_repository.dart';
import '../profile/data/profile_models.dart';
import '../profile/data/profile_repository.dart';
import '../tutors/tutor_avatar.dart';

/// Home dashboard (APP_FLOW §6). Every number comes from the server; nothing
/// is estimated on the device.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: switch (dashboard) {
          AsyncData(:final value) => _DashboardView(dashboard: value),
          AsyncError(:final error) => ListView(children: [
              SizedBox(
                height: 420,
                child: AppErrorState(failure: AppFailure.from(error), onRetry: () => ref.invalidate(dashboardProvider)),
              ),
            ]),
          _ => const _DashboardSkeleton(),
        },
      ),
    );
  }
}

String greeting(BuildContext context, String? name, DateTime now) {
  final l10n = context.l10n;
  final hasName = name != null && name.trim().isNotEmpty;
  if (now.hour < 12) return hasName ? l10n.homeGreetingMorningName(name) : l10n.homeGreetingMorning;
  if (now.hour < 18) return hasName ? l10n.homeGreetingAfternoonName(name) : l10n.homeGreetingAfternoon;
  return hasName ? l10n.homeGreetingEveningName(name) : l10n.homeGreetingEvening;
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final secondary = context.palette.textSecondary;
    final rec = dashboard.recommendation;
    final tutor = ref.watch(tutorByIdProvider(rec.tutorId));
    final scenario = rec.scenarioId == null ? null : ref.watch(scenarioByIdProvider(rec.scenarioId!));

    final todayMinutes = dashboard.todaySpeakingSeconds ~/ 60;
    final goal = dashboard.dailyGoalMinutes;
    final progress = goal == null || goal == 0 ? 0.0 : (todayMinutes / goal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Semantics(header: true, child: Text(greeting(context, dashboard.displayName, DateTime.now()), style: text.headlineSmall)),
        Gap.xs,
        Text(l10n.homeSubtitle, style: text.bodyLarge?.copyWith(color: secondary)),
        Gap.xl,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeTodayGoal, style: text.labelLarge?.copyWith(color: secondary)),
              const SizedBox(height: 6),
              Text(
                goal == null ? l10n.homeTodayMinutes(todayMinutes) : l10n.homeTodayProgress(todayMinutes, goal),
                style: text.titleLarge,
              ),
              const SizedBox(height: 10),
              Semantics(
                value: '${(progress * 100).round()}%',
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                ),
              ),
              Gap.md,
              Text(l10n.homeFreeTimeLeft(dashboard.remainingFreeSeconds ~/ 60), style: text.bodySmall),
            ],
          ),
        ),
        Gap.lg,
        AppButton(
          key: const ValueKey('home-start-speaking'),
          label: l10n.homeStartSpeaking,
          icon: Icons.mic_rounded,
          onPressed: () => context.push(AppRoutes.prepare(rec.tutorId, scenarioId: rec.scenarioId)),
        ),
        Gap.xl,
        Text(l10n.homeRecommended, style: text.titleMedium),
        Gap.sm,
        AppCard(
          onTap: () => context.push(AppRoutes.prepare(rec.tutorId, scenarioId: rec.scenarioId)),
          child: Row(
            children: [
              TutorAvatar(tutor: tutor),
              Gap.lg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario?.$2.title ?? tutor.name, style: text.titleSmall),
                    Text(
                      scenario == null ? tutor.title : '${tutor.name} · ${scenario.$2.levels}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: secondary),
            ],
          ),
        ),
        Gap.xl,
        Text(l10n.homeReview, style: text.titleMedium),
        Gap.sm,
        Row(
          children: [
            Expanded(
              child: _ReviewCard(
                icon: Icons.auto_fix_high_outlined,
                title: l10n.homeMistakeVault,
                message: l10n.homeMistakeVaultEmpty,
              ),
            ),
            Gap.md,
            Expanded(
              child: _ReviewCard(icon: Icons.style_outlined, title: l10n.homeVocabulary, message: l10n.homeVocabularyEmpty),
            ),
          ],
        ),
        Gap.xl,
        Text(l10n.homeYourProgress, style: text.titleMedium),
        Gap.sm,
        AppCard(
          child: Column(
            children: [
              _StatRow(icon: Icons.local_fire_department_outlined, label: l10n.homeStreak(dashboard.streakDays)),
              _StatRow(icon: Icons.timer_outlined, label: l10n.homeWeeklyMinutes(dashboard.weeklySpeakingSeconds ~/ 60)),
              _StatRow(icon: Icons.check_circle_outline, label: l10n.homeWeeklySessions(dashboard.weeklySessions)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => context.go(AppRoutes.learn),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.colors.primary),
            Gap.sm,
            Text(title, style: context.textStyles.titleSmall),
            Gap.xs,
            Text(message, style: context.textStyles.bodySmall),
          ],
        ),
      );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.primary),
            Gap.md,
            Expanded(child: Text(label, style: context.textStyles.bodyMedium)),
          ],
        ),
      );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          AppSkeleton(width: 220, height: 28),
          Gap.md,
          AppSkeleton(width: 260),
          Gap.xl,
          AppSkeleton(height: 120, radius: AppRadius.card),
          Gap.lg,
          AppSkeleton(height: 52, radius: AppRadius.button),
          Gap.xl,
          AppSkeleton(height: 72, radius: AppRadius.card),
        ],
      );
}
