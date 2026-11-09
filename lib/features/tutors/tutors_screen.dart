import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../practice/data/catalog_repository.dart';
import 'tutor.dart';
import 'tutor_avatar.dart';

/// Tutor selection (APP_FLOW §7). When opened for a scenario, the choice
/// replaces the tutor on the preparation screen.
class TutorsScreen extends ConsumerWidget {
  const TutorsScreen({super.key, this.scenarioId});

  final String? scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For a scenario, offer only the tutors the backend marks as compatible.
    final scenario = scenarioId == null ? null : ref.watch(scenarioByIdProvider(scenarioId!))?.$2;
    final tutors = ref.watch(tutorsProvider).whenData(
          (all) => scenario == null ? all : all.where((t) => scenario.compatibleTutorIds.contains(t.id)).toList(),
        );
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tutorsTitle)),
      body: switch (tutors) {
        AsyncData(:final value) when value.isEmpty => const AppEmptyState(
            title: 'No tutors available',
            message: 'Please check back soon.',
          ),
        AsyncData(:final value) => ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: value.length,
            separatorBuilder: (_, _) => Gap.md,
            itemBuilder: (context, i) => _TutorCard(
              tutor: value[i],
              onTap: () => context.pushReplacement(AppRoutes.prepare(value[i].id, scenarioId: scenarioId)),
            ),
          ),
        AsyncError(:final error) => AppErrorState(
            failure: AppFailure.from(error),
            onRetry: () => ref.invalidate(tutorsProvider),
          ),
        _ => const AppLoadingView(),
      },
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.tutor, required this.onTap});

  final Tutor tutor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final l10n = context.l10n;
    return AppCard(
      key: ValueKey('tutor-${tutor.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TutorAvatar(tutor: tutor, size: 56),
          Gap.lg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tutor.name, style: text.titleMedium),
                Text(tutor.title, style: text.bodyMedium?.copyWith(color: context.palette.primaryDark)),
                Gap.xs,
                Text(tutor.description, style: text.bodyMedium),
                Gap.sm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final trait in tutor.personality) _Chip(trait),
                    _Chip(l10n.practiceLevels(tutor.levels)),
                    if (!tutor.voiceAvailable) _Chip(l10n.tutorsVoiceSoon, muted: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: muted ? context.colors.surface : context.palette.primaryLight,
          border: muted ? Border.all(color: context.palette.border) : null,
          borderRadius: AppRadius.smallAll,
        ),
        child: Text(
          label,
          style: context.textStyles.labelMedium?.copyWith(
            color: muted ? context.palette.textSecondary : context.palette.primaryDark,
          ),
        ),
      );
}
