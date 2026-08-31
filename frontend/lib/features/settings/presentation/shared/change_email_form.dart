import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';

/// Leaf form atom shared by both Settings layouts — see auth's
/// AuthErrorBanner for why this lives outside presentation/{desktop,mobile}.
class ChangeEmailForm extends ConsumerStatefulWidget {
  const ChangeEmailForm({super.key});

  @override
  ConsumerState<ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends ConsumerState<ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _email.dispose();
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
        .updateAccount(email: _email.text.trim());
    setState(() {
      _loading = false;
      _success = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = ref.watch(sessionControllerProvider).user?.email ?? '';
    final error = ref.watch(sessionControllerProvider).errorMessage;

    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.emailSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.newEmailLabel,
              hintText: currentEmail,
            ),
            validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
                ? l10n.authEmailValidation
                : null,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: AppColors.error)),
          ],
          if (_success) ...[
            const SizedBox(height: 8),
            Text(
              l10n.emailUpdatedMessage,
              style: const TextStyle(color: AppColors.success),
            ),
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
                  : Text(l10n.saveEmailLabel),
            ),
          ),
        ],
      ),
    );
  }
}
