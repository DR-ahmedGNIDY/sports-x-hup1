import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
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
      setState(() => _error = 'This reset link is missing its token.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _done
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Your password has been reset. You can log in now.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Go to login'),
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
                        label: 'New password',
                        validator: (v) =>
                            (v == null || v.length < 8) ? 'At least 8 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmPassword,
                        label: 'Confirm new password',
                        validator: (v) =>
                            v != _password.text ? 'Passwords do not match' : null,
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
                            : const Text('Reset password'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
