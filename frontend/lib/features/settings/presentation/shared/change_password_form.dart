import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/presentation/shared/password_field.dart';

/// Leaf form atom shared by both Settings layouts — see ChangeEmailForm.
class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _success = false;
    });
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .updateAccount(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
    setState(() {
      _loading = false;
      _success = ok;
      if (ok) {
        _currentPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(sessionControllerProvider).errorMessage;
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.passwordLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          PasswordField(
            controller: _currentPassword,
            label: l10n.currentPasswordLabel,
            validator: (v) => (v == null || v.isEmpty) ? l10n.authPasswordValidation : null,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _newPassword,
            label: l10n.newPasswordLabel,
            validator: (v) => (v == null || v.length < 8) ? l10n.authPasswordMinLength : null,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _confirmPassword,
            label: l10n.confirmNewPasswordLabel,
            validator: (v) => v != _newPassword.text ? l10n.authPasswordMismatch : null,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: AppColors.error)),
          ],
          if (_success) ...[
            const SizedBox(height: 8),
            Text(l10n.passwordUpdatedMessage, style: const TextStyle(color: AppColors.success)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.changePasswordLabel),
            ),
          ),
        ],
      ),
    );
  }
}
