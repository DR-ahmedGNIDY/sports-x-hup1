import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/lookup_providers.dart';
import '../../application/club_profile_controller.dart';

/// Club identity — name, country, city, description, founded year, level.
class ClubInfoSection extends ConsumerStatefulWidget {
  const ClubInfoSection({super.key});

  @override
  ConsumerState<ClubInfoSection> createState() => _ClubInfoSectionState();
}

class _ClubInfoSectionState extends ConsumerState<ClubInfoSection> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _foundedYear = TextEditingController();
  final _level = TextEditingController();
  String? _country;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _description.dispose();
    _foundedYear.dispose();
    _level.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile = ref.read(clubProfileControllerProvider).value;
    if (profile == null || _initialized) return;
    _name.text = profile.name ?? '';
    _city.text = profile.city ?? '';
    _description.text = profile.description ?? '';
    _foundedYear.text = profile.foundedYear?.toString() ?? '';
    _level.text = profile.level ?? '';
    _country = profile.country;
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(clubProfileControllerProvider.notifier)
          .saveProfile(
            name: _name.text.trim(),
            country: _country,
            city: _city.text.trim(),
            description: _description.text.trim(),
            foundedYear: int.tryParse(_foundedYear.text),
            level: _level.text.trim(),
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
    final countries = ref.watch(countriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.clubInfoTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: l10n.clubNameLabel),
        ),
        const SizedBox(height: 12),
        countries.when(
          data: (options) => DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: InputDecoration(labelText: l10n.countryLabel),
            items: options
                .map((o) => DropdownMenuItem(value: o.name, child: Text(o.name)))
                .toList(),
            onChanged: (value) => setState(() => _country = value),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          decoration: InputDecoration(labelText: l10n.cityLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.descriptionLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _foundedYear,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.foundedYearLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _level,
          decoration: InputDecoration(
            labelText: l10n.levelLabel,
            hintText: l10n.levelHint,
          ),
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
                : Text(l10n.saveLabel),
          ),
        ),
      ],
    );
  }
}
