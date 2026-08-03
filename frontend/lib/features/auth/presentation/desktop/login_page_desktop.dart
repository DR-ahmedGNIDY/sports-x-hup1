import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../application/session_controller.dart';
import '../../application/session_state.dart';
import '../shared/auth_error_banner.dart';
import '../shared/password_field.dart';

class LoginPageDesktop extends ConsumerStatefulWidget {
  const LoginPageDesktop({super.key});

  @override
  ConsumerState<LoginPageDesktop> createState() => _LoginPageDesktopState();
}

class _LoginPageDesktopState extends ConsumerState<LoginPageDesktop> {
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
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: AppColors.brandBlueDark,
              alignment: Alignment.center,
              child: const Padding(
                padding: EdgeInsets.all(48),
                child: AppLogo(height: 120),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 24),
                      AuthErrorBanner(message: session.errorMessage),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _password,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Log in'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
