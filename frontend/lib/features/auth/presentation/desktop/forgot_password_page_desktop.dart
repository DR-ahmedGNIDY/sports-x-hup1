import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../shared/auth_error_banner.dart';

class ForgotPasswordPageDesktop extends ConsumerStatefulWidget {
  const ForgotPasswordPageDesktop({super.key});

  @override
  ConsumerState<ForgotPasswordPageDesktop> createState() =>
      _ForgotPasswordPageDesktopState();
}

class _ForgotPasswordPageDesktopState extends ConsumerState<ForgotPasswordPageDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      setState(() => _sent = true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(height: 72)),
              const SizedBox(height: 24),
              Text('Reset your password', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 12),
              if (_sent)
                const Text(
                  'If an account exists for that email, a reset link has been sent. '
                  'In development, check the backend console log for the link.',
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthErrorBanner(message: _error),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send reset link'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
