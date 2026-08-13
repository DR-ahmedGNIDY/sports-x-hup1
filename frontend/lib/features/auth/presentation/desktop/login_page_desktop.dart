import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/session_controller.dart';
import '../../application/session_state.dart';
import '../shared/auth_error_banner.dart';
import '../shared/auth_panel_seam.dart';
import '../shared/auth_video_panel.dart';
import '../shared/password_field.dart';

class LoginPageDesktop extends ConsumerStatefulWidget {
  const LoginPageDesktop({super.key});

  @override
  ConsumerState<LoginPageDesktop> createState() => _LoginPageDesktopState();
}

class _LoginPageDesktopState extends ConsumerState<LoginPageDesktop> {
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.authWelcomeBack,
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: 24),
                          AuthErrorBanner(message: session.errorMessage),
                          TextFormField(
                            controller: _identifier,
                            decoration: InputDecoration(
                              labelText: l10n.authIdentifierLabel,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.authIdentifierValidation
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _password,
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.authPasswordValidation
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: Text(l10n.authForgotPassword),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.authLogIn),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.authNoAccount),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: Text(l10n.authRegister),
                              ),
                            ],
                          ),
                        ],
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
