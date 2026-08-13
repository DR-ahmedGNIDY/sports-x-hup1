import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .login(identifier: _identifier.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isLoading = session.status == SessionStatus.authenticating;
    final l10n = AppLocalizations.of(context)!;

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
                Text(l10n.authLogIn, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 20),
                AuthErrorBanner(message: session.errorMessage),
                TextFormField(
                  controller: _identifier,
                  decoration: InputDecoration(labelText: l10n.authIdentifierLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.authIdentifierValidation
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.authPasswordValidation : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(l10n.authForgotPassword),
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
                      : Text(l10n.authLogIn),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(l10n.authNoAccountRegisterMobile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
