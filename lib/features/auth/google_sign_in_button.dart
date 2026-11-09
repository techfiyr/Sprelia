import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';

/// "Continue with Google" (APP_FLOW §3–4). After success the session and router
/// take over, exactly as for email sign-in.
///
/// Uses a generic icon on purpose: Google's official button artwork is a third-party
/// brand asset and is not bundled until it is licensed and added to the asset library.
/// Disabled when Google sign-in is not configured for this build.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key, this.enabled = true, this.onError});

  final bool enabled;

  /// Shows a user-safe message; defaults to a SnackBar.
  final ValueChanged<String>? onError;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  void _show(String message) {
    if (widget.onError != null) return widget.onError!(message);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await ref.read(accountAuthProvider).signInWithGoogle();
    } on AuthCancelled {
      // The user closed the picker: nothing to report.
    } on AuthFailure catch (e) {
      if (mounted) _show(e.message);
    } catch (e, st) {
      ref.read(errorReporterProvider).report(e, st, reason: 'Google sign-in failed');
      if (mounted) _show(mapAuthErrorCode('unknown').message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(accountAuthProvider).googleSignInAvailable;
    return AppButton.secondary(
      key: const ValueKey('auth-google'),
      label: context.l10n.authContinueWithGoogle,
      icon: Icons.account_circle_outlined,
      isLoading: _busy,
      onPressed: available && widget.enabled && !_busy ? _signIn : null,
    );
  }
}
