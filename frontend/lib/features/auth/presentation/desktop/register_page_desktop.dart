import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/session_controller.dart';
import '../../application/session_state.dart';
import '../../domain/entities/user_role.dart';
import '../shared/auth_error_banner.dart';
import '../shared/auth_panel_seam.dart';
import '../shared/auth_video_panel.dart';
import '../shared/password_field.dart';
import '../shared/role_picker.dart';

class RegisterPageDesktop extends ConsumerStatefulWidget {
  const RegisterPageDesktop({super.key});

  @override
  ConsumerState<RegisterPageDesktop> createState() => _RegisterPageDesktopState();
}

class _RegisterPageDesktopState extends ConsumerState<RegisterPageDesktop> {
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          const Expanded(
            child: AuthVideoPanel(assetPath: 'assets/videos/panar22.mp4'),
          ),
          Expanded(
            child: Stack(
              children: [
                const AuthPanelSeam(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.authCreateAccountTitle,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 24),
                            AuthErrorBanner(message: session.errorMessage),
                            RolePicker(
                              value: _role,
                              onChanged: (role) => setState(() => _role = role),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              decoration: InputDecoration(labelText: l10n.authEmailLabel),
                              validator: (v) =>
                                  (v == null || !v.contains('@')) ? l10n.authEmailValidation : null,
                            ),
                            const SizedBox(height: 16),
                            PasswordField(
                              controller: _password,
                              validator: (v) =>
                                  (v == null || v.length < 8) ? l10n.authPasswordMinLength : null,
                            ),
                            const SizedBox(height: 16),
                            PasswordField(
                              controller: _confirmPassword,
                              label: l10n.authConfirmPassword,
                              validator: (v) =>
                                  v != _password.text ? l10n.authPasswordMismatch : null,
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
                                  : Text(l10n.authCreateAccountTitle),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l10n.authAlreadyHaveAccount),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: Text(l10n.authLogIn),
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
          ),
        ],
      ),
    );
  }
}
