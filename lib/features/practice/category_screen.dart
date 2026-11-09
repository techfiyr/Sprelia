import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'data/catalog_repository.dart';

/// Scenarios of one practice category (APP_FLOW §8).
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(practiceCategoriesProvider);
    final category = categories.value?.where((c) => c.id == categoryId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(category?.title ?? l10n.practiceTitle)),
      body: switch (categories) {
        AsyncError(:final error) => AppErrorState(
            failure: AppFailure.from(error),
            onRetry: () => ref.invalidate(practiceCategoriesProvider),
          ),
        AsyncData() when category == null => AppEmptyState(
            icon: Icons.explore_off_outlined,
            title: "This category isn't available",
            message: l10n.practiceChooseAnotherCategory,
            actionLabel: l10n.practiceTitle,
            onAction: () => context.go(AppRoutes.practice),
          ),
        AsyncData() => ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: category!.scenarios.length,
            separatorBuilder: (_, _) => Gap.md,
            itemBuilder: (context, i) {
              final s = category.scenarios[i];
              return AppCard(
                key: ValueKey('scenario-${s.id}'),
                onTap: () => context.push(AppRoutes.prepare(s.suggestedTutorId, scenarioId: s.id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: context.textStyles.titleMedium),
                    Gap.xs,
                    Text(s.description, style: context.textStyles.bodyMedium),
                    Gap.sm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _Tag(l10n.practiceLevels(s.levels)),
                        _Tag(l10n.practiceAboutMinutes(s.estimatedMinutes)),
                        if (s.premium) _Tag(l10n.practicePremium, icon: Icons.workspace_premium_outlined),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        _ => const AppLoadingView(),
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(color: context.palette.primaryLight, borderRadius: AppRadius.smallAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: context.palette.primaryDark), const SizedBox(width: 4)],
            Text(label, style: context.textStyles.labelMedium?.copyWith(color: context.palette.primaryDark)),
          ],
        ),
      );
}
