import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../player/application/lookup_providers.dart';
import '../../player/domain/entities/contact_details.dart';
import '../../player/domain/entities/player_enums.dart';
import '../../player/presentation/shared/profile_photo_section.dart';
import '../../player/presentation/shared/section_card.dart';
import '../application/coach_providers.dart';
import '../data/coach_repository.dart';
import '../domain/coach_models.dart';
import 'shared/coach_cv_view.dart';
import 'shared/coach_widgets.dart';

// Same client-side caps as the player media editor (backend upload.config).
const int _kMaxPhotoBytes = 5 * 1024 * 1024;
const int _kMaxVideoBytes = 50 * 1024 * 1024;

/// `/coach/edit` — every part of the CV. The basic details save together
/// with one button; each list section (experience, certifications,
/// achievements, links) and the media album save item by item, the way the
/// player editor does.
class EditCoachProfilePage extends ConsumerWidget {
  const EditCoachProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(myCoachProfileProvider)
        .when(
          // Keyed on the id so the form's controllers are created once from
          // the loaded profile, not reset by every section save.
          data: (profile) => CoachPageBody(
            children: [
              ProfilePhotoSection(
                photoUrl: profile.profilePhotoUrl,
                onUpload: ref
                    .read(myCoachProfileProvider.notifier)
                    .uploadProfilePhoto,
              ),
              const SizedBox(height: AppSpacing.lg),
              _BasicsForm(key: ValueKey(profile.id), profile: profile),
              const SizedBox(height: AppSpacing.lg),
              _EntriesSection(
                title: l10n.coachExperienceTitle,
                icon: Icons.timeline,
                section: CoachCvSection.experience,
                emptyText: l10n.coachNoExperience,
                entries: [
                  for (final e in profile.experience)
                    _Entry(
                      id: e.id,
                      title: '${e.role} — ${e.clubName}',
                      subtitle:
                          '${e.startYear} – ${e.endYear?.toString() ?? l10n.coachToDate}',
                      values: {
                        'clubName': e.clubName,
                        'role': e.role,
                        'startYear': '${e.startYear}',
                        'endYear': e.endYear?.toString() ?? '',
                        'description': e.description ?? '',
                      },
                    ),
                ],
                fields: [
                  _Field('clubName', l10n.coachClubNameLabel, required: true),
                  _Field('role', l10n.coachRoleLabel, required: true),
                  _Field(
                    'startYear',
                    l10n.coachStartYearLabel,
                    required: true,
                    isYear: true,
                  ),
                  _Field('endYear', l10n.coachEndYearLabel, isYear: true),
                  _Field('description', l10n.descriptionLabel, multiline: true),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _EntriesSection(
                title: l10n.coachCertificationsTitle,
                icon: Icons.workspace_premium_outlined,
                section: CoachCvSection.certifications,
                emptyText: l10n.coachNoCertifications,
                entries: [
                  for (final c in profile.certifications)
                    _Entry(
                      id: c.id,
                      title: c.name,
                      subtitle: [
                        c.issuer,
                        c.year?.toString(),
                      ].whereType<String>().join(' · '),
                      values: {
                        'name': c.name,
                        'issuer': c.issuer ?? '',
                        'year': c.year?.toString() ?? '',
                      },
                    ),
                ],
                fields: [
                  _Field(
                    'name',
                    l10n.coachCertificationNameLabel,
                    required: true,
                  ),
                  _Field('issuer', l10n.coachIssuerLabel),
                  _Field('year', l10n.yearLabel, isYear: true),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _EntriesSection(
                title: l10n.achievementsTitle,
                icon: Icons.emoji_events_outlined,
                section: CoachCvSection.achievements,
                emptyText: l10n.noAchievementsYet,
                entries: [
                  for (final a in profile.achievements)
                    _Entry(
                      id: a.id,
                      title: a.title,
                      subtitle: '${a.year}',
                      values: {
                        'title': a.title,
                        'year': '${a.year}',
                        'description': a.description ?? '',
                      },
                    ),
                ],
                fields: [
                  _Field('title', l10n.achievementTitleLabel, required: true),
                  _Field('year', l10n.yearLabel, required: true, isYear: true),
                  _Field('description', l10n.descriptionLabel, multiline: true),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _EntriesSection(
                title: l10n.socialLinksTitle,
                icon: Icons.link,
                section: CoachCvSection.socialLinks,
                emptyText: l10n.noSocialLinksYet,
                entries: [
                  for (final s in profile.socialLinks)
                    _Entry(
                      id: s.id,
                      title: s.platform,
                      subtitle: s.url,
                      values: {'platform': s.platform, 'url': s.url},
                    ),
                ],
                fields: [
                  _Field('platform', l10n.platformLabel, required: true),
                  _Field('url', l10n.urlLabel, required: true),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _MediaEditor(media: profile.media),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error is AppException ? error.message : null,
            onRetry: () => ref.invalidate(myCoachProfileProvider),
          ),
        );
  }
}

// ------------------------------------------------------------- basics

class _BasicsForm extends ConsumerStatefulWidget {
  const _BasicsForm({super.key, required this.profile});

  final CoachProfile profile;

  @override
  ConsumerState<_BasicsForm> createState() => _BasicsFormState();
}

class _BasicsFormState extends ConsumerState<_BasicsForm> {
  late final CoachProfile p = widget.profile;
  late final _firstName = TextEditingController(text: p.firstName);
  late final _lastName = TextEditingController(text: p.lastName);
  late final _headline = TextEditingController(text: p.headline);
  late final _years = TextEditingController(
    text: p.yearsOfExperience?.toString(),
  );
  late final _nationality = TextEditingController(text: p.nationality);
  late final _country = TextEditingController(text: p.country);
  late final _city = TextEditingController(text: p.city);
  late final _bio = TextEditingController(text: p.bio);
  late final _education = TextEditingController(text: p.education);
  late final _specialties = TextEditingController(
    text: p.specialties.join('، '),
  );
  late final _formations = TextEditingController(
    text: p.preferredFormations.join('، '),
  );
  late final _languages = TextEditingController(text: p.languages.join('، '));
  late final _phone = TextEditingController(text: p.contact.phone);
  late final _whatsapp = TextEditingController(text: p.contact.whatsapp);
  late final _email = TextEditingController(text: p.contact.email);
  late String? _sport = p.sport;
  late DateTime? _dateOfBirth = p.dateOfBirth;
  bool _saving = false;
  String? _error;

  List<TextEditingController> get _controllers => [
    _firstName,
    _lastName,
    _headline,
    _years,
    _nationality,
    _country,
    _city,
    _bio,
    _education,
    _specialties,
    _formations,
    _languages,
    _phone,
    _whatsapp,
    _email,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Tags are typed as one comma-separated line; Arabic and Latin commas
  // both split.
  List<String> _tags(TextEditingController c) => c.text
      .split(RegExp('[,،]'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final years = _years.text.trim().isEmpty
        ? null
        : int.tryParse(_years.text.trim());
    if (_years.text.trim().isNotEmpty && (years == null || years < 0)) {
      setState(() => _error = l10n.coachYearsValidation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      String t(TextEditingController c) => c.text.trim();
      await ref
          .read(myCoachProfileProvider.notifier)
          .save(
            firstName: t(_firstName),
            lastName: t(_lastName),
            headline: t(_headline),
            yearsOfExperience: years,
            nationality: t(_nationality),
            country: t(_country),
            city: t(_city),
            sport: _sport,
            dateOfBirth: _dateOfBirth,
            bio: t(_bio),
            education: t(_education),
            specialties: _tags(_specialties),
            preferredFormations: _tags(_formations),
            languages: _tags(_languages),
            contact: ContactDetails(
              phone: t(_phone),
              whatsapp: t(_whatsapp),
              email: t(_email).isEmpty ? null : t(_email),
            ),
          );
      messenger.showSnackBar(SnackBar(content: Text(l10n.coachSavedFeedback)));
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sports = ref.watch(sportsProvider).valueOrNull ?? const [];
    Widget field(
      TextEditingController c,
      String label, {
      bool multiline = false,
      TextInputType? keyboard,
      String? hint,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: multiline ? 5 : 1,
        minLines: 1,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: b),
      ],
    );

    return ProfileSectionCard(
      icon: Icons.badge_outlined,
      title: l10n.coachBasicsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pair(
            field(_firstName, l10n.firstNameLabel),
            field(_lastName, l10n.lastNameLabel),
          ),
          field(
            _headline,
            l10n.coachHeadlineLabel,
            hint: l10n.coachHeadlineHint,
          ),
          pair(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DropdownButtonFormField<String>(
                initialValue: sports.any((s) => s.name == _sport)
                    ? _sport
                    : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.sportLabel),
                items: [
                  for (final s in sports)
                    DropdownMenuItem(value: s.name, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() => _sport = v),
              ),
            ),
            field(
              _years,
              l10n.coachYearsOfExperienceLabel,
              keyboard: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cake_outlined),
              label: Text(
                _dateOfBirth == null
                    ? l10n.dateOfBirthLabel
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(_dateOfBirth!),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth ?? DateTime(1985),
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dateOfBirth = picked);
              },
            ),
          ),
          pair(
            field(_nationality, l10n.nationalityLabel),
            field(_country, l10n.countryLabel),
          ),
          field(_city, l10n.cityLabel),
          field(_bio, l10n.bioLabel, multiline: true),
          field(_education, l10n.coachEducationLabel),
          field(
            _specialties,
            l10n.coachSpecialtiesLabel,
            hint: l10n.coachTagsHint,
          ),
          field(
            _formations,
            l10n.coachFormationsLabel,
            hint: l10n.coachFormationsHint,
          ),
          field(_languages, l10n.coachLanguagesLabel, hint: l10n.coachTagsHint),
          const Divider(),
          pair(
            field(_phone, l10n.phoneLabel, keyboard: TextInputType.phone),
            field(_whatsapp, l10n.whatsappLabel, keyboard: TextInputType.phone),
          ),
          field(
            _email,
            l10n.contactEmailLabel,
            keyboard: TextInputType.emailAddress,
          ),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
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
      ),
    );
  }
}

// ------------------------------------------------- repeatable sections

class _Field {
  const _Field(
    this.key,
    this.label, {
    this.required = false,
    this.isYear = false,
    this.multiline = false,
  });

  final String key;
  final String label;
  final bool required;
  final bool isYear;
  final bool multiline;
}

class _Entry {
  const _Entry({
    required this.id,
    required this.title,
    required this.values,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final Map<String, String> values;
}

/// A titled list of CV entries with add/edit/delete. One generic editor
/// for all four sections: they differ only in their fields.
class _EntriesSection extends ConsumerWidget {
  const _EntriesSection({
    required this.title,
    required this.icon,
    required this.section,
    required this.emptyText,
    required this.entries,
    required this.fields,
  });

  final String title;
  final IconData icon;
  final CoachCvSection section;
  final String emptyText;
  final List<_Entry> entries;
  final List<_Field> fields;

  Future<void> _edit(BuildContext context, WidgetRef ref, [_Entry? entry]) =>
      showDialog<void>(
        context: context,
        builder: (_) => _EntryDialog(
          title: title,
          section: section,
          fields: fields,
          entry: entry,
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileSectionCard(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entries.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodySmall),
          for (final entry in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.title),
              subtitle: entry.subtitle == null || entry.subtitle!.isEmpty
                  ? null
                  : Text(entry.subtitle!),
              onTap: () => _edit(context, ref, entry),
              trailing: IconButton(
                tooltip: l10n.deleteLabel,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(myCoachProfileProvider.notifier)
                        .removeEntry(section, entry.id);
                  } on AppException catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.coachAddEntry),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryDialog extends ConsumerStatefulWidget {
  const _EntryDialog({
    required this.title,
    required this.section,
    required this.fields,
    this.entry,
  });

  final String title;
  final CoachCvSection section;
  final List<_Field> fields;
  final _Entry? entry;

  @override
  ConsumerState<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends ConsumerState<_EntryDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: widget.entry?.values[f.key] ?? ''),
  };
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final body = <String, dynamic>{};
    for (final f in widget.fields) {
      final text = _controllers[f.key]!.text.trim();
      if (text.isEmpty) {
        if (f.required) {
          setState(() => _error = l10n.coachRequiredField(f.label));
          return;
        }
        continue;
      }
      if (f.isYear) {
        final year = int.tryParse(text);
        if (year == null || year < 1900 || year > 2100) {
          setState(() => _error = l10n.coachYearValidation(f.label));
          return;
        }
        body[f.key] = year;
      } else {
        body[f.key] = text;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(myCoachProfileProvider.notifier);
      final entry = widget.entry;
      if (entry == null) {
        await notifier.addEntry(widget.section, body);
      } else {
        await notifier.updateEntry(widget.section, entry.id, body);
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextField(
                    controller: _controllers[f.key],
                    keyboardType: f.isYear ? TextInputType.number : null,
                    maxLines: f.multiline ? 4 : 1,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: f.required ? '${f.label} *' : f.label,
                    ),
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l10n.saveLabel),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- media

class _MediaEditor extends ConsumerStatefulWidget {
  const _MediaEditor({required this.media});

  final List<CoachMedia> media;

  @override
  ConsumerState<_MediaEditor> createState() => _MediaEditorState();
}

class _MediaEditorState extends ConsumerState<_MediaEditor> {
  bool _uploading = false;
  String? _error;

  Future<void> _pick(PlayerMediaType type) async {
    final l10n = AppLocalizations.of(context)!;
    final isVideo = type == PlayerMediaType.video;
    final result = await FilePicker.pickFiles(
      withData: true,
      type: isVideo ? FileType.video : FileType.image,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    final max = isVideo ? _kMaxVideoBytes : _kMaxPhotoBytes;
    if (file.bytes!.length > max) {
      setState(() {
        _error = isVideo
            ? l10n.videoUploadTooLargeError(max ~/ (1024 * 1024))
            : l10n.photoUploadTooLargeError(max ~/ (1024 * 1024));
      });
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref
          .read(myCoachProfileProvider.notifier)
          .uploadMedia(bytes: file.bytes!, filename: file.name, type: type);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileSectionCard(
      icon: Icons.perm_media_outlined,
      title: l10n.photosVideosTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.media.isNotEmpty)
            CoachMediaGrid(
              media: widget.media,
              onDelete: (item) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(myCoachProfileProvider.notifier)
                      .deleteMedia(item.id);
                } on AppException catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _pick(PlayerMediaType.photo),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.addPhotoLabel),
              ),
              OutlinedButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _pick(PlayerMediaType.video),
                icon: const Icon(Icons.videocam_outlined),
                label: Text(l10n.addVideoLabel),
              ),
              if (_uploading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
