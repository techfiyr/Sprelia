import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../onboarding/onboarding_labels.dart';
import 'data/catalog_repository.dart';

/// Practice discovery (APP_FLOW §8): free conversation or a category.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(practiceCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.practiceTitle)),
      body: switch (categories) {
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => ref.refresh(practiceCategoriesProvider.future),
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Text(l10n.practiceSubtitle, style: context.textStyles.bodyLarge?.copyWith(color: context.palette.textSecondary)),
                Gap.lg,
                AppCard(
                  key: const ValueKey('practice-free-conversation'),
                  tone: AppCardTone.tinted,
                  onTap: () => context.push(AppRoutes.tutors),
                  child: _Row(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l10n.practiceFreeConversation,
                    subtitle: l10n.practiceFreeConversationDescription,
                  ),
                ),
                Gap.md,
                for (final c in value) ...[
                  AppCard(
                    key: ValueKey('category-${c.id}'),
                    onTap: () => context.go(AppRoutes.category(c.id)),
                    child: _Row(
                      icon: categoryIcon(c.icon),
                      title: c.title,
                      subtitle: '${c.description}\n${l10n.practiceScenarioCount(c.scenarios.length)}',
                    ),
                  ),
                  Gap.md,
                ],
              ],
            ),
          ),
        AsyncError(:final error) => AppErrorState(
            failure: AppFailure.from(error),
            onRetry: () => ref.invalidate(practiceCategoriesProvider),
          ),
        _ => const AppLoadingView(),
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: context.palette.primaryLight, borderRadius: AppRadius.inputAll),
            child: Icon(icon, color: context.palette.primaryDark),
          ),
          Gap.lg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: context.textStyles.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.textSecondary),
        ],
      );
}
