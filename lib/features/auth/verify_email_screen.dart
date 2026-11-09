import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';

/// Email verification gate (APP_FLOW §4 "email verification as appropriate"; owner
/// decision D1, recommended). Shown to signed-in email/password accounts whose email
/// is not verified yet. The backend enforces the same rule (EMAIL_NOT_VERIFIED).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  /// Minimum time between "resend" taps (Firebase also rate-limits sends).
  static const resendCooldown = Duration(seconds: 60);

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  int _cooldown = 0;
  bool _checking = false;
  bool _sending = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = VerifyEmailScreen.resendCooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
    });
    final l10n = context.l10n;
    try {
      await ref.read(accountAuthProvider).sendEmailVerification();
      if (mounted) setState(() => _info = l10n.verifyEmailSent);
      _startCooldown();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, st) {
      ref.read(errorReporterProvider).report(e, st, reason: 'Resend verification failed');
      if (mounted) setState(() => _error = mapAuthErrorCode('unknown').message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
      _info = null;
    });
    final l10n = context.l10n;
    try {
      final user = await ref.read(accountAuthProvider).refreshUser();
      // When verified, refreshUser() emits the updated user on the auth stream; the
      // session rebuilds once and the router moves on (no extra reload, which would
      // race and send duplicate profile requests).
      if ((user == null || user.needsEmailVerification) && mounted) {
        setState(() => _error = l10n.verifyEmailNotYet);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, st) {
      ref.read(errorReporterProvider).report(e, st, reason: 'Verification check failed');
      if (mounted) setState(() => _error = mapAuthErrorCode('unknown').message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final session = ref.watch(sessionProvider).value;
    final email = switch (session) {
      NeedsEmailVerification(:final user) => user.email ?? '',
      _ => '',
    };
    final busy = _checking || _sending;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Gap.xl,
            Icon(Icons.mark_email_unread_outlined, size: 56, color: context.colors.primary),
            Gap.lg,
            Text(l10n.verifyEmailTitle, style: text.headlineMedium),
            Gap.sm,
            Text(l10n.verifyEmailBody(email), style: text.bodyLarge?.copyWith(color: context.palette.textSecondary)),
            if (_error != null) ...[
              Gap.md,
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: text.bodyMedium?.copyWith(color: context.colors.error)),
              ),
            ],
            if (_info != null) ...[
              Gap.md,
              Semantics(
                liveRegion: true,
                child: Text(_info!, style: text.bodyMedium?.copyWith(color: context.palette.successText)),
              ),
            ],
            Gap.xl,
            AppButton(
              key: const ValueKey('verify-check'),
              label: l10n.verifyEmailCheck,
              isLoading: _checking,
              onPressed: busy ? null : _check,
            ),
            Gap.md,
            AppButton.secondary(
              key: const ValueKey('verify-resend'),
              label: _cooldown > 0 ? l10n.verifyEmailResendIn(_cooldown) : l10n.verifyEmailResend,
              onPressed: busy || _cooldown > 0 ? null : _resend,
            ),
            Gap.md,
            AppButton.text(
              key: const ValueKey('verify-sign-out'),
              label: l10n.verifyEmailUseAnotherAccount,
              expand: true,
              onPressed: busy ? null : () => ref.read(sessionProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
