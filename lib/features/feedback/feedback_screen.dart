import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../learn/data/learning_repository.dart';
import 'session_feedback.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(feedbackProvider(conversationId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your feedback'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => context.go(AppRoutes.home)),
        ],
      ),
      body: feedback.when(
        loading: () => AppLoadingView(message: context.l10n.feedbackAnalyzing),
        error: (e, _) => AppErrorState(
          failure: e is TimeoutException
              ? const ServerFailure(statusCode: 0, message: 'Feedback is taking longer than expected. Please try again.')
              : AppFailure.from(e),
          onRetry: () => ref.invalidate(feedbackProvider(conversationId)),
        ),
        data: (result) => switch (result) {
          FeedbackCompleted(:final feedback) => _FeedbackBody(feedback: feedback),
          FeedbackFailed(:final message) => AppErrorState(
              failure: ServerFailure(statusCode: 0, message: message),
              onRetry: () => ref.invalidate(feedbackProvider(conversationId)),
            ),
          FeedbackInsufficientSpeech() || FeedbackPending() => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'That conversation was too short for feedback. Try speaking a little longer next time!',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _FeedbackBody extends StatelessWidget {
  const _FeedbackBody({required this.feedback});

  final SessionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(feedback.summary, style: text.bodyLarge),
        if (feedback.strengths.isNotEmpty) ...[
          _Heading('Strengths'),
          ...feedback.strengths.map((s) => _Bullet(s, icon: Icons.check_circle_outline, color: palette.success)),
        ],
        if (feedback.corrections.isNotEmpty) ...[
          _Heading('Corrections'),
          ...feedback.corrections.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.category.toUpperCase(),
                            style: text.labelSmall?.copyWith(letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text(c.original,
                            style: text.bodyMedium?.copyWith(
                              color: palette.danger,
                              decoration: TextDecoration.lineThrough,
                            )),
                        const SizedBox(height: 4),
                        Text(c.improved,
                            style: text.bodyMedium?.copyWith(
                              color: palette.successText,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 8),
                        Text(c.explanation, style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
              )),
        ],
        if (feedback.vocabulary.isNotEmpty) ...[
          _Heading('Vocabulary'),
          ...feedback.vocabulary.map((v) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(v.term, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${v.meaning}\n“${v.example}”'),
                isThreeLine: true,
              )),
        ],
        if (feedback.fluencyObservations.isNotEmpty) ...[
          _Heading('Communication tips'),
          ...feedback.fluencyObservations.map((s) => _Bullet(s, icon: Icons.lightbulb_outline)),
        ],
        if (feedback.recommendedPractice.isNotEmpty) ...[
          _Heading(context.l10n.feedbackPracticeNext),
          ...feedback.recommendedPractice.map((s) => _Bullet(s, icon: Icons.arrow_forward)),
        ],
        const SizedBox(height: 24),
        AppButton(label: 'Done', onPressed: () => context.go(AppRoutes.home)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(label,
            style: context.textStyles.titleMedium),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {required this.icon, this.color});
  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color ?? context.colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ]),
      );
}
