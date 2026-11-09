import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';

/// Email sign-in and account creation (APP_FLOW §4). After success the
/// session and router take over (profile check → onboarding or home).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _error;
  String? _info;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_creating) {
        await auth.createAccountWithEmail(email: _email.text, password: _password.text);
      } else {
        await auth.signInWithEmail(email: _email.text, password: _password.text);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, st) {
      ref.read(errorReporterProvider).report(e, st, reason: 'Email auth failed');
      if (mounted) setState(() => _error = mapAuthErrorCode('unknown').message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = context.l10n.authEmailInvalid);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    } on AuthFailure {
      // Same confirmation either way: never reveal whether an account exists.
    }
    if (mounted) setState(() => _info = context.l10n.authResetSent(email));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              children: [
                Text(_creating ? l10n.authCreateTitle : l10n.authSignInTitle, style: text.headlineMedium),
                Gap.sm,
                Text(
                  _creating ? l10n.authCreateSubtitle : l10n.authSignInSubtitle,
                  style: text.bodyLarge?.copyWith(color: context.palette.textSecondary),
                ),
                Gap.xl,
                AppTextField(
                  key: const ValueKey('auth-email'),
                  label: l10n.authEmailLabel,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: Icons.mail_outline_rounded,
                  enabled: !_busy,
                  validator: (v) => _emailPattern.hasMatch((v ?? '').trim()) ? null : l10n.authEmailInvalid,
                ),
                Gap.lg,
                AppTextField.password(
                  key: const ValueKey('auth-password'),
                  label: l10n.authPasswordLabel,
                  controller: _password,
                  textInputAction: TextInputAction.done,
                  autofillHints: [_creating ? AutofillHints.newPassword : AutofillHints.password],
                  enabled: !_busy,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v ?? '').length >= 8 ? null : l10n.authPasswordTooShort,
                ),
                if (!_creating)
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton.text(label: l10n.authForgotPassword, onPressed: _busy ? null : _resetPassword),
                  ),
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
                  key: const ValueKey('auth-submit'),
                  label: _creating ? l10n.authCreateAction : l10n.authSignInAction,
                  isLoading: _busy,
                  onPressed: _submit,
                ),
                Gap.md,
                AppButton.text(
                  label: _creating ? l10n.authSwitchToSignIn : l10n.authSwitchToCreate,
                  expand: true,
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _creating = !_creating;
                            _error = null;
                            _info = null;
                          }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
