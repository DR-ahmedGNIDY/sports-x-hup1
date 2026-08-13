import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../shared/auth_error_banner.dart';
import '../shared/auth_panel_seam.dart';
import '../shared/auth_video_panel.dart';

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
                          l10n.authForgotPasswordTitle,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 12),
                        if (_sent)
                          Text(l10n.authForgotSentMessage)
                        else
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthErrorBanner(message: _error),
                                TextFormField(
                                  controller: _email,
                                  decoration: InputDecoration(labelText: l10n.authEmailLabel),
                                  validator: (v) => (v == null || !v.contains('@'))
                                      ? l10n.authEmailValidation
                                      : null,
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
                                      : Text(l10n.authSendResetLink),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.authBackToLogin),
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
