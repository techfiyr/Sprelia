import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding/brand_art.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../premium/ad_banner.dart';
import 'guest_trial.dart';

/// The one free introductory lesson, playable without an account. It is fully local (no backend,
/// no AI, no microphone): a guest has no verified identity, so nothing server-side can run for
/// them. Finishing it records a device flag and offers account creation; it unlocks nothing.
///
/// Copy is intentionally in code (a single short lesson), not in the localization files.
sealed class _Step {
  const _Step();
}

class _Meet extends _Step {
  const _Meet();
}

class _SayIt extends _Step {
  const _SayIt(this.phrase, this.hint);
  final String phrase;
  final String hint;
}

class _Choose extends _Step {
  const _Choose(this.prompt, this.options, this.answer, this.praise);
  final String prompt;
  final List<String> options;
  final int answer;
  final String praise;
}

class _Order extends _Step {
  const _Order(this.prompt, this.words);
  final String prompt;
  final List<String> words;
}

const _steps = <_Step>[
  _Meet(),
  _SayIt('Hi, I\'m Alex. Nice to meet you!', 'Read it out loud, with a big smile.'),
  _Choose(
    'Someone says: "Nice to meet you!"\nWhat is a friendly reply?',
    ['Nice to meet you too!', 'Yes, I am.', 'Goodbye.'],
    0,
    'Yes! "Nice to meet you too" is the classic reply.',
  ),
  _Choose(
    'Complete the question:\n"Where are you ___?"',
    ['from', 'with', 'for'],
    0,
    'Perfect: "Where are you from?" is how we ask about home.',
  ),
  _Order('Tap the words in order to build a sentence.', ['I', 'am', 'learning', 'English']),
];

class GuestLessonScreen extends ConsumerStatefulWidget {
  const GuestLessonScreen({super.key});

  @override
  ConsumerState<GuestLessonScreen> createState() => _GuestLessonScreenState();
}

class _GuestLessonScreenState extends ConsumerState<GuestLessonScreen> {
  var _index = 0;
  var _canContinue = false;

  bool get _finished => _index >= _steps.length;

  void _next() {
    setState(() {
      _index++;
      _canContinue = false;
    });
    if (_finished) ref.read(guestLessonDoneProvider.notifier).markDone();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_index / _steps.length).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: BrandPalette.cream,
      appBar: AppBar(
        backgroundColor: BrandPalette.cream,
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.sm,
        title: Row(
          children: [
            IconButton(
              tooltip: 'Close lesson',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.go(AppRoutes.welcome),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: BrandPalette.peach,
                  color: BrandPalette.coral,
                  semanticsLabel: 'Lesson progress',
                ),
              ),
            ),
            Gap.md,
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _finished
                ? const _Celebration(key: ValueKey('done'))
                : _StepView(
                    key: ValueKey(_index),
                    step: _steps[_index],
                    canContinue: _canContinue,
                    onReady: () => setState(() => _canContinue = true),
                    onContinue: _next,
                  ),
          ),
        ),
      ),
      bottomNavigationBar: const AdBannerArea(),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    super.key,
    required this.step,
    required this.canContinue,
    required this.onReady,
    required this.onContinue,
  });

  final _Step step;
  final bool canContinue;
  final VoidCallback onReady;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final body = switch (step) {
      _Meet() => Column(
          children: [
            const TutorMascot(size: 200),
            Gap.lg,
            Text('Hi, I\'m Hermione!', style: text.headlineSmall, textAlign: TextAlign.center),
            Gap.sm,
            Text(
              'Let\'s try a quick lesson together: introducing yourself in English. It takes about two minutes.',
              style: text.bodyLarge?.copyWith(color: context.palette.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      _SayIt(:final phrase, :final hint) => _SayItBody(phrase: phrase, hint: hint, onDone: onReady, done: canContinue),
      _Choose() => _ChooseBody(step: step as _Choose, onCorrect: onReady),
      _Order(:final prompt, :final words) => _OrderBody(prompt: prompt, words: words, onDone: onReady),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: body))),
        AppButton(
          key: const ValueKey('lesson-continue'),
          label: step is _Meet ? 'Let\'s start' : 'Continue',
          onPressed: step is _Meet || canContinue ? onContinue : null,
        ),
      ],
    );
  }
}

class _SayItBody extends StatelessWidget {
  const _SayItBody({required this.phrase, required this.hint, required this.onDone, required this.done});

  final String phrase;
  final String hint;
  final VoidCallback onDone;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Column(
      children: [
        Text('Say it out loud', style: text.titleMedium?.copyWith(color: BrandPalette.coralText)),
        Gap.lg,
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BrandPalette.peach, width: 2),
          ),
          child: Text(phrase, style: text.headlineSmall?.copyWith(color: BrandPalette.plumDeep), textAlign: TextAlign.center),
        ),
        Gap.md,
        Text(hint, style: text.bodyMedium?.copyWith(color: context.palette.textSecondary), textAlign: TextAlign.center),
        Gap.xl,
        AppButton.secondary(
          key: const ValueKey('lesson-said-it'),
          label: done ? 'Nicely done!' : 'I said it',
          icon: done ? Icons.check_circle_rounded : Icons.record_voice_over_rounded,
          onPressed: done ? null : onDone,
        ),
      ],
    );
  }
}

class _ChooseBody extends StatefulWidget {
  const _ChooseBody({required this.step, required this.onCorrect});

  final _Choose step;
  final VoidCallback onCorrect;

  @override
  State<_ChooseBody> createState() => _ChooseBodyState();
}

class _ChooseBodyState extends State<_ChooseBody> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final step = widget.step;
    final correct = _picked == step.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(step.prompt, style: text.titleLarge?.copyWith(color: BrandPalette.plumDeep)),
        Gap.xl,
        for (var i = 0; i < step.options.length; i++) ...[
          _ChoiceTile(
            label: step.options[i],
            state: _picked != i
                ? _ChoiceState.idle
                : (i == step.answer ? _ChoiceState.right : _ChoiceState.wrong),
            onTap: correct
                ? null
                : () {
                    setState(() => _picked = i);
                    if (i == step.answer) widget.onCorrect();
                  },
          ),
          Gap.md,
        ],
        if (_picked != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              correct ? step.praise : 'Not quite. Have another go!',
              style: text.bodyLarge?.copyWith(color: correct ? context.palette.successText : context.colors.error, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

enum _ChoiceState { idle, right, wrong }

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.label, required this.state, required this.onTap});

  final String label;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (border, fill) = switch (state) {
      _ChoiceState.idle => (BrandPalette.peach, Colors.white),
      _ChoiceState.right => (palette.success, palette.success.withValues(alpha: 0.12)),
      _ChoiceState.wrong => (context.colors.error, palette.danger.withValues(alpha: 0.1)),
    };
    return Semantics(
      button: true,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: border, width: 2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: Text(label, style: context.textStyles.titleMedium),
          ),
        ),
      ),
    );
  }
}

class _OrderBody extends StatefulWidget {
  const _OrderBody({required this.prompt, required this.words, required this.onDone});

  final String prompt;
  final List<String> words;
  final VoidCallback onDone;

  @override
  State<_OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends State<_OrderBody> {
  late final List<String> _pool = [...widget.words]..shuffle();
  final List<String> _built = [];

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final done = _built.length == widget.words.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.prompt, style: text.titleLarge?.copyWith(color: BrandPalette.plumDeep)),
        Gap.xl,
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: done ? context.palette.success : BrandPalette.peach, width: 2),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final w in _built) Chip(label: Text(w), backgroundColor: BrandPalette.sun.withValues(alpha: 0.35))],
          ),
        ),
        Gap.xl,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final w in _pool)
              if (!_built.contains(w))
                ActionChip(
                  label: Text(w, style: text.titleMedium),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: BrandPalette.peach, width: 2),
                  onPressed: () {
                    // Only the next word in the sentence is accepted.
                    if (w == widget.words[_built.length]) {
                      setState(() => _built.add(w));
                      if (_built.length == widget.words.length) widget.onDone();
                    }
                  },
                ),
          ],
        ),
        if (done) ...[
          Gap.lg,
          Text('"I am learning English." Great sentence!',
              style: text.bodyLarge?.copyWith(color: context.palette.successText, fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}

class _Celebration extends ConsumerWidget {
  const _Celebration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Gap.lg,
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 44, color: BrandPalette.sun),
                    Icon(Icons.star_rounded, size: 64, color: BrandPalette.sun),
                    Icon(Icons.star_rounded, size: 44, color: BrandPalette.sun),
                  ],
                ),
                Gap.md,
                Text('You finished your first lesson!',
                    style: text.headlineSmall?.copyWith(color: BrandPalette.plumDeep, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                Gap.md,
                Text(
                  'Create a free account to save your progress and keep learning. Full access to every lesson, tutor and conversation needs a Hermione subscription.',
                  style: text.bodyLarge?.copyWith(color: context.palette.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        AppButton(
          key: const ValueKey('lesson-create-account'),
          label: 'Create account or sign in',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
        Gap.sm,
        AppButton.text(
          label: 'Back to start',
          expand: true,
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ],
    );
  }
}
