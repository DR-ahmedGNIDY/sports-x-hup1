import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/contact_controller.dart';

/// Leaf form — same pattern as ChangePasswordForm/ChangeEmailForm in
/// Settings: field-level state stays local, only the submit result is
/// centralized (ContactController). Reused by both Desktop and Mobile
/// Contact pages.
class ContactForm extends ConsumerStatefulWidget {
  const ContactForm({super.key});

  @override
  ConsumerState<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(contactControllerProvider.notifier)
        .submit(name: _name.text.trim(), email: _email.text.trim(), message: _message.text.trim());
    if (ref.read(contactControllerProvider).success) {
      _name.clear();
      _email.clear();
      _message.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(contactControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _message,
            decoration: const InputDecoration(labelText: 'Message'),
            minLines: 4,
            maxLines: 8,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          if (formState.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(formState.errorMessage!, style: const TextStyle(color: AppColors.error)),
          ],
          if (formState.success) ...[
            const SizedBox(height: 8),
            const Text(
              'Thanks — we received your message and will get back to you soon.',
              style: TextStyle(color: AppColors.success),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: formState.submitting ? null : _submit,
            child: formState.submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send message'),
          ),
        ],
      ),
    );
  }
}
