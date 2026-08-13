import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Leaf atom (obscure-toggling password input) shared by every auth screen
/// on both platforms — see AuthErrorBanner for why this is here and not
/// duplicated under presentation/desktop and presentation/mobile.
class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.label, this.validator});

  final TextEditingController controller;
  /// Defaults to the localized "Password" label — null rather than a
  /// hardcoded default because a translatable default can't be a Dart
  /// compile-time constant.
  final String? label;
  final String? Function(String?)? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label ?? AppLocalizations.of(context)!.passwordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
