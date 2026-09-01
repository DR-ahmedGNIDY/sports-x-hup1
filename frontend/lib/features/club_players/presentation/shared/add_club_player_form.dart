import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/lookup_providers.dart';
import '../../../player/domain/entities/basketball_position.dart';
import '../../../player/domain/entities/football_position.dart';
import '../../../player/domain/entities/player_enums.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/create_club_player_input.dart';
import '../../domain/entities/dial_codes.dart';
import 'whatsapp_send_button.dart';

const _stepCount = 4;

/// Full player-creation flow, as a 4-step guided wizard (Basic Information →
/// Sports Information → Contact → Account) instead of one long scrolling
/// form. Shared verbatim between Desktop and Mobile — [isDesktop] only picks
/// the step-indicator chrome and button layout; the field logic, validation,
/// and submit flow are identical. The caller (the Desktop/Mobile page file)
/// decides [isDesktop], since individual widgets don't branch on
/// `MediaQuery`/`AppBreakpoints` themselves (see `core/utils/breakpoints.dart`).
class AddClubPlayerForm extends ConsumerStatefulWidget {
  const AddClubPlayerForm({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  ConsumerState<AddClubPlayerForm> createState() => _AddClubPlayerFormState();
}

class _AddClubPlayerFormState extends ConsumerState<AddClubPlayerForm> {
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _nationality = TextEditingController();
  final _city = TextEditingController();
  final _positionFreeText = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _bio = TextEditingController();

  String? _countryIsoCode;
  String? _sport;
  String? _position;
  PreferredFoot? _preferredFoot;
  DateTime? _dateOfBirth;
  int _step = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _nationality.dispose();
    _city.dispose();
    _positionFreeText.dispose();
    _height.dispose();
    _weight.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 60),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _goNext() {
    setState(() => _error = null);
    if (_step == 0) {
      if (!_basicInfoFormKey.currentState!.validate()) return;
      final l10n = AppLocalizations.of(context)!;
      if (_countryIsoCode == null) {
        setState(() => _error = l10n.clubPlayerSelectCountryError);
        return;
      }
    }
    if (_step == 2 && !_contactFormKey.currentState!.validate()) return;
    if (_step < _stepCount - 1) setState(() => _step++);
  }

  void _goBack() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final input = CreateClubPlayerInput(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        countryIsoCode: _countryIsoCode!,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        dateOfBirth: _dateOfBirth,
        nationality: _emptyToNull(_nationality.text),
        city: _emptyToNull(_city.text),
        sport: _sport,
        position: isFootballSport(_sport) || isBasketballSport(_sport)
            ? _position
            : _emptyToNull(_positionFreeText.text),
        preferredFoot: _preferredFoot,
        height: num.tryParse(_height.text),
        weight: num.tryParse(_weight.text),
        bio: _emptyToNull(_bio.text),
      );
      final credentials = await ref
          .read(clubPlayersActionsProvider)
          .addPlayer(input);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.clubPlayerAccountCreatedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.clubPlayerUsernameValue(credentials.username)),
              const SizedBox(height: 4),
              Text(l10n.clubPlayerPasswordValue(credentials.password)),
              const SizedBox(height: 16),
              SendCredentialsWhatsAppButton(
                firstName: input.firstName,
                credentials: credentials,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/club/players');
              },
              child: Text(l10n.clubPlayerDoneLabel),
            ),
          ],
        ),
      );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepTitles = [
      l10n.clubPlayerStepBasicInfoTitle,
      l10n.clubPlayerStepSportsInfoTitle,
      l10n.clubPlayerStepContactTitle,
      l10n.clubPlayerStepAccountTitle,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.isDesktop
            ? _DesktopStepHeader(step: _step, titles: stepTitles)
            : _MobileStepHeader(
                step: _step,
                total: _stepCount,
                title: stepTitles[_step],
              ),
        const SizedBox(height: 24),
        _buildStepContent(l10n),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 20),
        _buildNavButtons(l10n),
      ],
    );
  }

  Widget _buildStepContent(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _buildBasicInfoStep(l10n);
      case 1:
        return _buildSportsInfoStep(l10n);
      case 2:
        return _buildContactStep(l10n);
      default:
        return _buildAccountStep(l10n);
    }
  }

  String? _requiredValidator(String? v, AppLocalizations l10n) =>
      (v == null || v.trim().isEmpty)
      ? l10n.clubPlayerFieldRequiredValidation
      : null;

  Widget _buildBasicInfoStep(AppLocalizations l10n) {
    final countries = ref.watch(countriesProvider);
    return Form(
      key: _basicInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _firstName,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerFirstNameLabel,
            ),
            validator: (v) => _requiredValidator(v, l10n),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastName,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerLastNameLabel,
            ),
            validator: (v) => _requiredValidator(v, l10n),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _dateOfBirth != null
                  ? l10n.clubPlayerDobValueLabel(
                      DateFormat.yMd().format(_dateOfBirth!),
                    )
                  : l10n.clubPlayerDobOptionalLabel,
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDateOfBirth,
          ),
          const SizedBox(height: 12),
          countries.when(
            data: (options) => DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _countryIsoCode,
              decoration: InputDecoration(
                labelText: l10n.clubPlayerCountryLabel,
              ),
              items: options
                  .where((o) => o.code != null)
                  .map(
                    (o) => DropdownMenuItem(value: o.code, child: Text(o.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _countryIsoCode = value),
              validator: (v) =>
                  v == null ? l10n.clubPlayerFieldRequiredValidation : null,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerCityOptionalLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nationality,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerNationalityOptionalLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsInfoStep(AppLocalizations l10n) {
    final sports = ref.watch(sportsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sports.when(
          data: (options) => DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _sport,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerSportOptionalLabel,
            ),
            items: options
                .map(
                  (o) => DropdownMenuItem(value: o.name, child: Text(o.name)),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _sport = value;
              _position = null;
              _positionFreeText.clear();
            }),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        if (isFootballSport(_sport))
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _position,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerPositionOptionalLabel,
            ),
            items: footballPositionCodes
                .map(
                  (code) => DropdownMenuItem(
                    value: code,
                    child: Text(footballPositionFullName(l10n, code)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _position = value),
          )
        else if (isBasketballSport(_sport))
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _position,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerPositionOptionalLabel,
            ),
            items: basketballPositionCodes
                .map(
                  (code) => DropdownMenuItem(
                    value: code,
                    child: Text(basketballPositionFullName(l10n, code)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _position = value),
          )
        else
          TextFormField(
            controller: _positionFreeText,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerPositionOptionalLabel,
            ),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PreferredFoot>(
          initialValue: _preferredFoot,
          decoration: InputDecoration(
            labelText: l10n.clubPlayerPreferredFootOptionalLabel,
          ),
          items: PreferredFoot.values
              .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
              .toList(),
          onChanged: (value) => setState(() => _preferredFoot = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _height,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.clubPlayerHeightLabel,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.clubPlayerWeightLabel,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bio,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.clubPlayerBioOptionalLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep(AppLocalizations l10n) {
    final dialCode = _countryIsoCode != null
        ? kDialCodes[_countryIsoCode]
        : null;
    return Form(
      key: _contactFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerPhoneLabel,
              prefixText: dialCode != null ? '$dialCode ' : null,
              hintText: l10n.clubPlayerPhoneHint,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.clubPlayerFieldRequiredValidation
                : (!RegExp(r'^\d{6,14}$').hasMatch(v.trim())
                      ? l10n.clubPlayerPhoneInvalid
                      : null),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.clubPlayerEmailOptionalLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep(AppLocalizations l10n) {
    final dialCode = _countryIsoCode != null
        ? kDialCodes[_countryIsoCode]
        : null;
    final fullName = '${_firstName.text} ${_lastName.text}'.trim();
    final phoneDisplay = dialCode != null
        ? '$dialCode ${_phone.text}'
        : _phone.text;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clubPlayerReviewTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.clubPlayerReviewSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _ReviewRow(label: l10n.clubPlayerFirstNameLabel, value: fullName),
            _ReviewRow(label: l10n.clubPlayerPhoneLabel, value: phoneDisplay),
            if (_sport != null && _sport!.isNotEmpty)
              _ReviewRow(
                label: l10n.clubPlayerSportOptionalLabel,
                value: _sport!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButtons(AppLocalizations l10n) {
    final isLastStep = _step == _stepCount - 1;
    final nextButton = FilledButton(
      onPressed: _saving ? null : (isLastStep ? _submit : _goNext),
      child: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isLastStep
                  ? l10n.clubPlayerCreateAccountButton
                  : l10n.clubPlayerNextLabel,
            ),
    );
    final backButton = OutlinedButton(
      onPressed: _saving ? null : _goBack,
      child: Text(l10n.backLabel),
    );

    if (widget.isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_step > 0) ...[backButton, const SizedBox(width: 12)],
          nextButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nextButton,
        if (_step > 0) ...[const SizedBox(height: 8), backButton],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Desktop step chrome: a horizontal row of numbered circles connected by
/// lines, with the step title below the active one — a denser, at-a-glance
/// indicator that fits the wider desktop card.
class _DesktopStepHeader extends StatelessWidget {
  const _DesktopStepHeader({required this.step, required this.titles});

  final int step;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < titles.length; i++) ...[
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= step
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i <= step
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                titles[i],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: i == step
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: i == step ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
          if (i < titles.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Divider(
                  color: i < step
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  thickness: 2,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Mobile step chrome: a compact "Step X of N" label + progress bar — a
/// vertical-scan-friendly indicator instead of the Desktop's wide row of
/// circles, which wouldn't fit a narrow screen without shrinking.
class _MobileStepHeader extends StatelessWidget {
  const _MobileStepHeader({
    required this.step,
    required this.total,
    required this.title,
  });

  final int step;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.clubPlayerStepIndicatorLabel(step + 1, total),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: LinearProgressIndicator(
            value: (step + 1) / total,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
