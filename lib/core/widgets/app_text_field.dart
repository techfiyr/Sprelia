import 'package:flutter/material.dart';

/// Themed text input. Use [AppTextField.password] for secrets: obscured by
/// default, with an accessible show/hide toggle, no autocorrect/suggestions.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.prefixIcon,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
  }) : _isPassword = false;

  const AppTextField.password({
    super.key,
    this.label = 'Password',
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
  })  : _isPassword = true,
        keyboardType = TextInputType.visiblePassword,
        prefixIcon = Icons.lock_outline;

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final bool _isPassword;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget._isPassword;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return TextFormField(
      controller: w.controller,
      validator: w.validator,
      onChanged: w.onChanged,
      onFieldSubmitted: w.onSubmitted,
      keyboardType: w.keyboardType,
      textInputAction: w.textInputAction,
      autofillHints: w.enabled ? w.autofillHints : null,
      maxLength: w.maxLength,
      enabled: w.enabled,
      autofocus: w.autofocus,
      obscureText: _obscured,
      autocorrect: !w._isPassword,
      enableSuggestions: !w._isPassword,
      decoration: InputDecoration(
        labelText: w.label,
        hintText: w.hint,
        helperText: w.helperText,
        errorText: w.errorText,
        prefixIcon: w.prefixIcon == null ? null : Icon(w.prefixIcon),
        suffixIcon: w._isPassword
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
