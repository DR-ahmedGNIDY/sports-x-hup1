import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/presentation/shared/password_field.dart';

/// Leaf form atom shared by both Settings layouts — see ChangeEmailForm.
///
/// Two gates before anything is deleted: the password (checked server-side)
/// and a final confirm dialog. On success the session goes unauthenticated
/// and the router redirects to login, so there is no success state here.
class DeleteAccountForm extends ConsumerStatefulWidget {
  const DeleteAccountForm({super.key, this.onDeleted});

  /// Called after a successful delete while this form is still mounted —
  /// lets a sheet hosting it close itself instead of lingering over login.
  final VoidCallback? onDeleted;

  @override
  ConsumerState<DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends ConsumerState<DeleteAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ref
        .read(sessionControllerProvider.notifier)
        .deleteAccount(_password.text);
    // On success this widget may already be gone (the router left Settings
    // for login); only a failure has anything left to show.
    if (!mounted) return;
    if (error == null) {
      widget.onDeleted?.call();
      return;
    }
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deleteAccountLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deleteAccountWarning,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            label: l10n.deleteAccountPasswordLabel,
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.authPasswordValidation : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.deleteAccountConfirmButton),
            ),
          ),
        ],
      ),
    );
  }
}
