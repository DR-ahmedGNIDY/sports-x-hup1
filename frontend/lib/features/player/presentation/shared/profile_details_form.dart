import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/lookup_providers.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/basketball_position.dart';
import '../../domain/entities/contact_details.dart';
import '../../domain/entities/football_position.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_profile.dart';
import 'basketball_position_editor_types.dart';
import 'football_position_editor_types.dart';
import 'player_enum_labels.dart';

/// Matches [PlayerProfileController.saveProfile]'s signature exactly, so
/// that notifier method can be passed directly as [ProfileDetailsForm.onSave]
/// with no wrapper needed.
typedef ProfileDetailsSaveCallback =
    Future<void> Function({
      String? firstName,
      String? lastName,
      DateTime? dateOfBirth,
      String? nationality,
      String? country,
      String? city,
      String? sport,
      String? position,
      PreferredFoot? preferredFoot,
      num? height,
      num? weight,
      String? currentStatus,
      String? currentClub,
      String? bio,
      ContactDetails? contact,
    });

/// Personal info + sports info + bio/contact, merged into one form with a
/// single Save action instead of three separate section-level "Save"
/// buttons. Players were losing typed-but-unsaved input by switching
/// sections before hitting that section's own tiny Save button — one form,
/// one save, no ambiguity about what's been persisted. On success it
/// drops the player onto their profile so Save reads as "I'm done".
///
/// When `sport` is Football or Basketball, the free-text position field is
/// replaced by the matching sport's visual position picker —
/// [footballPositionEditorBuilder] / [basketballPositionEditorBuilder] are
/// supplied by the desktop/mobile Edit Profile page so this shared form
/// never branches on platform itself; it only owns the parsed
/// `_footballPositions` / `_basketballPositions` state and keeps the
/// underlying `position` string in sync with whichever sport is active.
///
/// [initialProfile]/[onSave]/[onSaved] default to the signed-in Player's
/// own profile (via [playerProfileControllerProvider]) — the Player's own
/// Edit Profile page doesn't pass them and behaves exactly as before. The
/// Club's Edit Managed Player page passes all three so this same form/
/// validation/position-picker logic edits a specific managed player
/// instead, without duplicating any of it.
class ProfileDetailsForm extends ConsumerStatefulWidget {
  const ProfileDetailsForm({
    super.key,
    required this.footballPositionEditorBuilder,
    required this.basketballPositionEditorBuilder,
    this.initialProfile,
    this.onSave,
    this.onSaved,
    this.saveLabel,
  });

  final FootballPositionEditorBuilder footballPositionEditorBuilder;
  final BasketballPositionEditorBuilder basketballPositionEditorBuilder;

  /// Overrides reading the signed-in Player's own profile.
  final PlayerProfile? initialProfile;

  /// Overrides [PlayerProfileController.saveProfile] as the save action.
  final ProfileDetailsSaveCallback? onSave;

  /// Overrides navigating to `/player/preview` after a successful save.
  final VoidCallback? onSaved;

  /// Overrides the Save button's label — the default
  /// "Save and view profile" wording assumes [onSaved] lands on the
  /// Player's own profile, which isn't true for the Club's Edit Managed
  /// Player page.
  final String? saveLabel;

  @override
  ConsumerState<ProfileDetailsForm> createState() => _ProfileDetailsFormState();
}

class _ProfileDetailsFormState extends ConsumerState<ProfileDetailsForm> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nationality = TextEditingController();
  final _city = TextEditingController();
  final _position = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _currentStatus = TextEditingController();
  final _currentClub = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _whatsapp = TextEditingController();

  DateTime? _dateOfBirth;
  String? _country;
  String? _sport;
  PreferredFoot? _preferredFoot;
  List<String> _footballPositions = const [];
  List<String> _basketballPositions = const [];
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _nationality.dispose();
    _city.dispose();
    _position.dispose();
    _height.dispose();
    _weight.dispose();
    _currentStatus.dispose();
    _currentClub.dispose();
    _bio.dispose();
    _phone.dispose();
    _email.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile = widget.initialProfile ?? ref.read(playerProfileControllerProvider).value;
    if (profile == null || _initialized) return;
    _firstName.text = profile.firstName ?? '';
    _lastName.text = profile.lastName ?? '';
    _nationality.text = profile.nationality ?? '';
    _city.text = profile.city ?? '';
    _position.text = profile.position ?? '';
    _footballPositions = parseFootballPositions(profile.position);
    _basketballPositions = parseBasketballPositions(profile.position);
    _height.text = profile.height?.toString() ?? '';
    _weight.text = profile.weight?.toString() ?? '';
    _currentStatus.text = profile.currentStatus ?? '';
    _currentClub.text = profile.currentClub ?? '';
    _bio.text = profile.bio ?? '';
    _phone.text = profile.contact.phone ?? '';
    _email.text = profile.contact.email ?? '';
    _whatsapp.text = profile.contact.whatsapp ?? '';
    _dateOfBirth = profile.dateOfBirth;
    _country = profile.country;
    _sport = profile.sport;
    _preferredFoot = profile.preferredFoot;
    _initialized = true;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _onFootballPositionTap(String code) {
    setState(() {
      final positions = List<String>.of(_footballPositions);
      if (positions.isNotEmpty && positions.first == code) {
        positions.removeAt(0);
      } else {
        positions.remove(code);
        positions.insert(0, code);
      }
      _footballPositions = positions;
      _position.text = formatFootballPositions(positions);
    });
  }

  void _onFootballPositionLongPress(String code) {
    setState(() {
      final positions = List<String>.of(_footballPositions);
      if (positions.contains(code)) {
        if (positions.first != code) positions.remove(code);
      } else {
        positions.add(code);
      }
      _footballPositions = positions;
      _position.text = formatFootballPositions(positions);
    });
  }

  void _onBasketballPositionTap(String code) {
    setState(() {
      final positions = List<String>.of(_basketballPositions);
      if (positions.isNotEmpty && positions.first == code) {
        positions.removeAt(0);
      } else {
        positions.remove(code);
        positions.insert(0, code);
      }
      _basketballPositions = positions;
      _position.text = formatBasketballPositions(positions);
    });
  }

  void _onBasketballPositionLongPress(String code) {
    setState(() {
      final positions = List<String>.of(_basketballPositions);
      if (positions.contains(code)) {
        if (positions.first != code) positions.remove(code);
      } else {
        positions.add(code);
      }
      _basketballPositions = positions;
      _position.text = formatBasketballPositions(positions);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final save = widget.onSave ?? ref.read(playerProfileControllerProvider.notifier).saveProfile;
      await save(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        dateOfBirth: _dateOfBirth,
        nationality: _nationality.text.trim(),
        country: _country,
        city: _city.text.trim(),
        sport: _sport,
        position: _position.text.trim(),
        preferredFoot: _preferredFoot,
        height: num.tryParse(_height.text),
        weight: num.tryParse(_weight.text),
        currentStatus: _currentStatus.text.trim(),
        currentClub: _currentClub.text.trim(),
        bio: _bio.text.trim(),
        contact: ContactDetails(
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        ),
      );
      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          context.go('/player/preview');
        }
      }
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
    final sports = ref.watch(sportsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.personalInfoTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _firstName,
          decoration: InputDecoration(labelText: l10n.firstNameLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _lastName,
          decoration: InputDecoration(labelText: l10n.lastNameLabel),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDateOfBirth,
          child: InputDecorator(
            decoration: InputDecoration(labelText: l10n.dateOfBirthLabel),
            child: Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                  : l10n.selectDateLabel,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nationality,
          decoration: InputDecoration(labelText: l10n.nationalityLabel),
        ),
        const SizedBox(height: 12),
        countries.when(
          data: (options) => DropdownButtonFormField<String>(
            initialValue: options.any((o) => o.name == _country) ? _country : null,
            isExpanded: true,
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
        TextField(controller: _city, decoration: InputDecoration(labelText: l10n.cityLabel)),
        const SizedBox(height: 28),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(l10n.sportsInfoTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        sports.when(
          data: (options) => DropdownButtonFormField<String>(
            initialValue: options.any((o) => o.name == _sport) ? _sport : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.sportLabel),
            items: options
                .map((o) => DropdownMenuItem(value: o.name, child: Text(o.name)))
                .toList(),
            onChanged: (value) => setState(() => _sport = value),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        if (isFootballSport(_sport))
          widget.footballPositionEditorBuilder(
            context,
            sport: _sport,
            positions: _footballPositions,
            onTap: _onFootballPositionTap,
            onLongPress: _onFootballPositionLongPress,
          )
        else if (isBasketballSport(_sport))
          widget.basketballPositionEditorBuilder(
            context,
            sport: _sport,
            positions: _basketballPositions,
            onTap: _onBasketballPositionTap,
            onLongPress: _onBasketballPositionLongPress,
          )
        else
          TextField(
            controller: _position,
            decoration: InputDecoration(labelText: l10n.positionLabel),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PreferredFoot>(
          initialValue: _preferredFoot,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.preferredFootLabel),
          items: PreferredFoot.values
              .map((f) => DropdownMenuItem(value: f, child: Text(preferredFootLabel(l10n, f))))
              .toList(),
          onChanged: (value) => setState(() => _preferredFoot = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _height,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.heightLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weight,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.weightLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentStatus,
          decoration: InputDecoration(labelText: l10n.currentStatusLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentClub,
          decoration: InputDecoration(labelText: l10n.currentClubLabel),
        ),
        const SizedBox(height: 28),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(l10n.aboutContactTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(controller: _bio, maxLines: 4, decoration: InputDecoration(labelText: l10n.bioLabel)),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l10n.phoneLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l10n.contactEmailLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l10n.whatsappLabel),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(widget.saveLabel ?? l10n.saveAndViewProfileLabel),
        ),
      ],
    );
  }
}
