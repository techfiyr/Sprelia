import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/errors/app_failure.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../onboarding/onboarding_draft_store.dart';
import 'account_repository.dart';

/// Account deletion (APP_FLOW §17).
///
/// POLICY STATUS: immediate hard delete is the engineering recommendation (D2), NOT an
/// owner-approved policy; the retention policy APP_FLOW §17 requires is not published yet.
/// Both are release blockers (doc/roadmap/phase_3.md).
///
/// 1. Confirm (destructive, cannot be undone).
/// 2. Re-authenticate (password or Google) so the ID token has a fresh `auth_time`;
///    the backend refuses older sign-ins with REAUTH_REQUIRED.
/// 3. `DELETE /api/v1/me`: the backend deletes all Firestore data, then the Auth user.
/// 4. Clear device-local data for this user and sign out.
Future<void> runDeleteAccountFlow(BuildContext context, WidgetRef ref, AuthUser user) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void show(String message) => messenger.showSnackBar(SnackBar(content: Text(message)));

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Text(l10n.deleteAccountBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        TextButton(
          key: const ValueKey('delete-account-confirm'),
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final account = ref.read(accountAuthProvider);
  try {
    if (user.usesPassword) {
      final password = await _askPassword(context);
      if (password == null) return;
      await account.reauthenticateWithPassword(password);
    } else if (user.usesGoogle) {
      await account.reauthenticateWithGoogle();
    }
  } on AuthCancelled {
    return;
  } on AuthFailure catch (e) {
    show(e.message);
    return;
  }
  if (!context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  // Progress dialog; closed below via the root navigator.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(content: Row(children: [const CircularProgressIndicator(), Gap.lg, Expanded(child: Text(l10n.deleteAccountInProgress))])),
    ),
  ));
  try {
    await ref.read(accountRepositoryProvider).deleteAccount();
    navigator.pop();
    await ref.read(onboardingDraftStoreProvider).clear(user.uid);
    // The Auth user no longer exists; end the local session (and Google's).
    await ref.read(sessionProvider.notifier).signOut();
  } on ReauthRequiredFailure {
    navigator.pop();
    show(mapAuthErrorCode('requires-recent-login').message);
  } catch (e, st) {
    navigator.pop();
    ref.read(errorReporterProvider).report(e, st, reason: 'Account deletion failed');
    show(AppFailure.from(e).message);
  }
}

Future<String?> _askPassword(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _PasswordDialog());

/// Owns its controller so it is disposed with the dialog (not while it animates out).
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.isEmpty ? null : _controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.reauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reauthPasswordBody),
          Gap.md,
          AppTextField.password(
            key: const ValueKey('reauth-password'),
            label: l10n.authPasswordLabel,
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        TextButton(key: const ValueKey('reauth-continue'), onPressed: _submit, child: Text(l10n.reauthContinue)),
      ],
    );
  }
}
