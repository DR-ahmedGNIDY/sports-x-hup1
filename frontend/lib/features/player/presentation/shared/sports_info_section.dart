import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/lookup_providers.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/player_enums.dart';

/// Sport, position, preferred foot, height/weight, current status/club.
class SportsInfoSection extends ConsumerStatefulWidget {
  const SportsInfoSection({super.key});

  @override
  ConsumerState<SportsInfoSection> createState() => _SportsInfoSectionState();
}

class _SportsInfoSectionState extends ConsumerState<SportsInfoSection> {
  final _position = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _currentStatus = TextEditingController();
  final _currentClub = TextEditingController();
  String? _sport;
  PreferredFoot? _preferredFoot;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _position.dispose();
    _height.dispose();
    _weight.dispose();
    _currentStatus.dispose();
    _currentClub.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile = ref.read(playerProfileControllerProvider).value;
    if (profile == null || _initialized) return;
    _position.text = profile.position ?? '';
    _height.text = profile.height?.toString() ?? '';
    _weight.text = profile.weight?.toString() ?? '';
    _currentStatus.text = profile.currentStatus ?? '';
    _currentClub.text = profile.currentClub ?? '';
    _sport = profile.sport;
    _preferredFoot = profile.preferredFoot;
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
            sport: _sport,
            position: _position.text.trim(),
            preferredFoot: _preferredFoot,
            height: num.tryParse(_height.text),
            weight: num.tryParse(_weight.text),
            currentStatus: _currentStatus.text.trim(),
            currentClub: _currentClub.text.trim(),
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
    final sports = ref.watch(sportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sports Information', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        sports.when(
          data: (options) => DropdownButtonFormField<String>(
            initialValue: _sport,
            decoration: const InputDecoration(labelText: 'Sport'),
            items: options
                .map((o) => DropdownMenuItem(value: o.name, child: Text(o.name)))
                .toList(),
            onChanged: (value) => setState(() => _sport = value),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _position,
          decoration: const InputDecoration(labelText: 'Position'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PreferredFoot>(
          initialValue: _preferredFoot,
          decoration: const InputDecoration(labelText: 'Preferred foot'),
          items: PreferredFoot.values
              .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
              .toList(),
          onChanged: (value) => setState(() => _preferredFoot = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _height,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Height (cm)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weight,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentStatus,
          decoration: const InputDecoration(labelText: 'Current status'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentClub,
          decoration: const InputDecoration(labelText: 'Current club'),
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
