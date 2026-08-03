import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../application/session_controller.dart';
import '../../application/session_state.dart';
import '../shared/auth_error_banner.dart';
import '../shared/password_field.dart';

class LoginPageMobile extends ConsumerStatefulWidget {
  const LoginPageMobile({super.key});

  @override
  ConsumerState<LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends ConsumerState<LoginPageMobile> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isLoading = session.status == SessionStatus.authenticating;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Center(child: AppLogo(height: 64)),
                const SizedBox(height: 32),
                Text('Log in', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 20),
                AuthErrorBanner(message: session.errorMessage),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
