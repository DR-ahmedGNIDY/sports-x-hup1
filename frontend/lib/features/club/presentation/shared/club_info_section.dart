import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/lookup_providers.dart';
import '../../application/club_profile_controller.dart';
import '../../domain/entities/club_level.dart';
import 'club_level_labels.dart';

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
  String? _country;

  // `null` covers two different cases the save logic must tell apart:
  // "the club hasn't picked a level yet" and "the stored value is legacy
  // free text this dropdown doesn't represent" — see [_legacyLevel] for
  // the second one. Either way, leaving this null means `level` is
  // omitted from the save request entirely (see `_save`), so a legacy
  // value already on the profile is never overwritten just because the
  // club edited an unrelated field.
  ClubLevel? _level;
  String? _legacyLevel;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _description.dispose();
    _foundedYear.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile = ref.read(clubProfileControllerProvider).value;
    if (profile == null || _initialized) return;
    _name.text = profile.name ?? '';
    _city.text = profile.city ?? '';
    _description.text = profile.description ?? '';
    _foundedYear.text = profile.foundedYear?.toString() ?? '';
    _country = profile.country;
    _level = ClubLevel.fromWire(profile.level);
    _legacyLevel = (_level == null && profile.level != null && profile.level!.isNotEmpty)
        ? profile.level
        : null;
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
            // Omitted (not sent as empty/null) when the club never picked
            // a value from the dropdown — see the `_level` doc comment.
            level: _level?.wireValue,
          );
      // A freshly-picked value replaces whatever legacy text was showing.
      if (_level != null) setState(() => _legacyLevel = null);
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
        DropdownButtonFormField<ClubLevel>(
          // Without this the dropdown sizes itself to its widest label and
          // overflows the field on a phone — which it started doing once the
          // compact type scale (M1) put body text at 16 instead of 14.
          isExpanded: true,
          initialValue: _level,
          decoration: InputDecoration(
            labelText: l10n.levelLabel,
            helperText: _legacyLevel != null
                ? l10n.clubLevelLegacyValueHint(_legacyLevel!)
                : null,
            helperMaxLines: 2,
          ),
          items: ClubLevel.values
              .map((level) => DropdownMenuItem(value: level, child: Text(clubLevelLabel(l10n, level))))
              .toList(),
          onChanged: (value) => setState(() => _level = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
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
