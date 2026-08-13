import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../shared/auth_error_banner.dart';
import '../shared/auth_panel_seam.dart';
import '../shared/auth_video_panel.dart';
import '../shared/password_field.dart';

class ResetPasswordPageDesktop extends ConsumerStatefulWidget {
  const ResetPasswordPageDesktop({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordPageDesktop> createState() =>
      _ResetPasswordPageDesktopState();
}

class _ResetPasswordPageDesktopState extends ConsumerState<ResetPasswordPageDesktop> {
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.authResetPasswordTitle,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 12),
                        if (_done)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l10n.authResetDoneMessage),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/login'),
                                child: Text(l10n.authGoToLogin),
                              ),
                            ],
                          )
                        else
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthErrorBanner(message: _error),
                                PasswordField(
                                  controller: _password,
                                  label: l10n.newPasswordLabel,
                                  validator: (v) => (v == null || v.length < 8)
                                      ? l10n.authPasswordMinLength
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                PasswordField(
                                  controller: _confirmPassword,
                                  label: l10n.confirmNewPasswordLabel,
                                  validator: (v) =>
                                      v != _password.text ? l10n.authPasswordMismatch : null,
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
                                      : Text(l10n.authResetPasswordButton),
                                ),
                              ],
                            ),
                          ),
                      ],
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
