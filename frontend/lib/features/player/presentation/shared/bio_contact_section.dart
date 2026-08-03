import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/contact_details.dart';

/// Bio plus the three contact channels (phone/email/WhatsApp) a Club uses
/// in Phase 3's Simple Contact. Saved together as one full contact object
/// so an untouched field is never wiped out by a partial edit elsewhere.
class BioContactSection extends ConsumerStatefulWidget {
  const BioContactSection({super.key});

  @override
  ConsumerState<BioContactSection> createState() => _BioContactSectionState();
}

class _BioContactSectionState extends ConsumerState<BioContactSection> {
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _whatsapp = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _bio.dispose();
    _phone.dispose();
    _email.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile = ref.read(playerProfileControllerProvider).value;
    if (profile == null || _initialized) return;
    _bio.text = profile.bio ?? '';
    _phone.text = profile.contact.phone ?? '';
    _email.text = profile.contact.email ?? '';
    _whatsapp.text = profile.contact.whatsapp ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(playerProfileControllerProvider.notifier)
          .saveProfile(
            bio: _bio.text.trim(),
            contact: ContactDetails(
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
            ),
          );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProfile();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('About & Contact', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Bio'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Contact email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp number'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
