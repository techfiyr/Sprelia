import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/realtime/realtime_provider.dart';
import '../../core/theme/app_theme.dart';
import '../tutors/tutor.dart';
import '../tutors/tutor_avatar.dart';
import 'conversation_controller.dart';
import 'conversation_state.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.tutorId});

  final String tutorId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationControllerProvider(widget.tutorId).notifier).start();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = conversationControllerProvider(widget.tutorId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final tutor = tutorById(widget.tutorId);
    final text = Theme.of(context).textTheme;

    ref.listen(provider, (prev, next) {
      if (prev?.status != ConversationStatus.ended && next.status == ConversationStatus.ended) {
        final id = next.conversationId;
        if (id != null) {
          context.pushReplacement('/feedback/$id');
        } else {
          context.pop();
        }
      }
      if ((prev?.transcript.length ?? 0) != next.transcript.length ||
          prev?.transcript.lastOrNull?.text != next.transcript.lastOrNull?.text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
        });
      }
    });

    return PopScope(
      canPop: state.status != ConversationStatus.live,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.end();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              TutorAvatar(tutor: tutor, size: 32, active: state.tutorSpeaking),
              const SizedBox(width: 10),
              Text(tutor.name),
            ],
          ),
          actions: [
            _ConnectionChip(status: state.status),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _TimerBar(state: state),
              Expanded(child: _buildBody(context, state, controller, tutor)),
              if (state.lastResponseLatencyMs != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Response latency ≈ ${state.lastResponseLatencyMs} ms',
                      style: text.labelSmall?.copyWith(color: AppColors.inkMuted)),
                ),
              _Controls(state: state, controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConversationState state,
    ConversationController controller,
    Tutor tutor,
  ) {
    final text = Theme.of(context).textTheme;
    if (state.status == ConversationStatus.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(state.error ?? 'Something went wrong.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: controller.start, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (state.status == ConversationStatus.connecting && state.transcript.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Connecting to ${tutor.name}…', style: text.bodyMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: state.transcript.length,
      itemBuilder: (context, i) => _Bubble(line: state.transcript[i], tutor: tutor),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line, required this.tutor});

  final TranscriptLine line;
  final Tutor tutor;

  @override
  Widget build(BuildContext context) {
    final isLearner = line.speaker == Speaker.learner;
    return Align(
      alignment: isLearner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: isLearner ? AppColors.primary : AppColors.surface,
          border: isLearner ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          line.text,
          style: TextStyle(color: isLearner ? Colors.white : AppColors.ink, height: 1.35),
        ),
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.state});

  final ConversationState state;

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = state.maxSeconds == 0 ? 0.0 : state.elapsedSeconds / state.maxSeconds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(_fmt(state.elapsedSeconds)),
              const Spacer(),
              Text('${_fmt(state.remainingSeconds)} left',
                  style: const TextStyle(color: AppColors.inkMuted)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.status});

  final ConversationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConversationStatus.live => ('Live', AppColors.success),
      ConversationStatus.connecting => ('Connecting', AppColors.warning),
      ConversationStatus.failed => ('Offline', AppColors.danger),
      _ => ('Ended', AppColors.inkMuted),
    };
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.controller});

  final ConversationState state;
  final ConversationController controller;

  @override
  Widget build(BuildContext context) {
    final live = state.status == ConversationStatus.live;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton.filledTonal(
            iconSize: 28,
            padding: const EdgeInsets.all(16),
            onPressed: live ? controller.toggleMute : null,
            tooltip: state.muted ? 'Unmute' : 'Mute',
            icon: Icon(state.muted ? Icons.mic_off_rounded : Icons.mic_rounded),
          ),
          IconButton.filled(
            iconSize: 28,
            padding: const EdgeInsets.all(16),
            style: IconButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: (live || state.status == ConversationStatus.connecting)
                ? () => controller.end()
                : (state.status == ConversationStatus.failed ? () => context.pop() : null),
            tooltip: 'End conversation',
            icon: const Icon(Icons.call_end_rounded),
          ),
        ],
      ),
    );
  }
}
