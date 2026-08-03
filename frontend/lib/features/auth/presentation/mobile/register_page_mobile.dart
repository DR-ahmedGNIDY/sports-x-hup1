import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../application/session_controller.dart';
import '../../application/session_state.dart';
import '../../domain/entities/user_role.dart';
import '../shared/auth_error_banner.dart';
import '../shared/password_field.dart';
import '../shared/role_picker.dart';

class RegisterPageMobile extends ConsumerStatefulWidget {
  const RegisterPageMobile({super.key});

  @override
  ConsumerState<RegisterPageMobile> createState() => _RegisterPageMobileState();
}

class _RegisterPageMobileState extends ConsumerState<RegisterPageMobile> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  UserRole _role = UserRole.player;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .register(email: _email.text.trim(), password: _password.text, role: _role);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isLoading = session.status == SessionStatus.authenticating;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(height: 56)),
                const SizedBox(height: 24),
                Text('Create account', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 20),
                AuthErrorBanner(message: session.errorMessage),
                Center(
                  child: RolePicker(
                    value: _role,
                    onChanged: (role) => setState(() => _role = role),
                  ),
                ),
                const SizedBox(height: 16),
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
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
