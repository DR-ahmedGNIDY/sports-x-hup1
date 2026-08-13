import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../shared/auth_error_banner.dart';
import '../shared/password_field.dart';

class ResetPasswordPageMobile extends ConsumerStatefulWidget {
  const ResetPasswordPageMobile({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordPageMobile> createState() =>
      _ResetPasswordPageMobileState();
}

class _ResetPasswordPageMobileState extends ConsumerState<ResetPasswordPageMobile> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = widget.token;
    if (token == null) {
      setState(() => _error = AppLocalizations.of(context)!.authResetTokenMissing);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, newPassword: _password.text);
      setState(() => _done = true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authResetPasswordAppBarTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _done
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.authResetDoneMessage),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: Text(l10n.authGoToLogin),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthErrorBanner(message: _error),
                      PasswordField(
                        controller: _password,
                        label: l10n.newPasswordLabel,
                        validator: (v) =>
                            (v == null || v.length < 8) ? l10n.authPasswordMinLength : null,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmPassword,
                        label: l10n.confirmNewPasswordLabel,
                        validator: (v) =>
                            v != _password.text ? l10n.authPasswordMismatch : null,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.authResetPasswordButton),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
