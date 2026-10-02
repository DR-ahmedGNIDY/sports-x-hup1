import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/admin_site_settings_controller.dart';
import '../domain/entities/site_settings.dart';

/// Links and contact details shown on the public website (sportxhup.com).
///
/// One form, one Save: these are a handful of fields edited rarely, so a
/// per-field save would only add buttons. Leaving a field empty hides that
/// item on the website.
class AdminSiteSettingsPage extends ConsumerWidget {
  const AdminSiteSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(adminSiteSettingsControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardAdminSiteSettings,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.adminSiteSettingsIntro,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: settings.when(
              // Keyed on the stored value so a save that normalises a field
              // (e.g. lower-casing the email) re-seeds the form with it.
              data: (value) => _SiteSettingsForm(
                key: ValueKey(value.toJson().toString()),
                initial: value,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                onRetry: () =>
                    ref.invalidate(adminSiteSettingsControllerProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteSettingsForm extends ConsumerStatefulWidget {
  const _SiteSettingsForm({super.key, required this.initial});

  final SiteSettings initial;

  @override
  ConsumerState<_SiteSettingsForm> createState() => _SiteSettingsFormState();
}

class _PhoneRow {
  _PhoneRow(SitePhone phone)
    : label = TextEditingController(text: phone.label),
      number = TextEditingController(text: phone.number);

  final TextEditingController label;
  final TextEditingController number;

  void dispose() {
    label.dispose();
    number.dispose();
  }
}

class _SiteSettingsFormState extends ConsumerState<_SiteSettingsForm> {
  static const _maxPhones = 6;
  static final _phonePattern = RegExp(r'^\+?[0-9 ]{6,20}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  late final _facebook = TextEditingController(
    text: widget.initial.facebookUrl,
  );
  late final _instagram = TextEditingController(
    text: widget.initial.instagramUrl,
  );
  late final _x = TextEditingController(text: widget.initial.xUrl);
  late final _tiktok = TextEditingController(text: widget.initial.tiktokUrl);
  late final _youtube = TextEditingController(text: widget.initial.youtubeUrl);
  late final _whatsapp = TextEditingController(
    text: widget.initial.whatsappNumber,
  );
  late final _email = TextEditingController(text: widget.initial.email);
  late final _googlePlay = TextEditingController(
    text: widget.initial.googlePlayUrl,
  );
  late final _webApp = TextEditingController(text: widget.initial.webAppUrl);
  late final List<_PhoneRow> _phones = [
    for (final p in widget.initial.phones) _PhoneRow(p),
  ];
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _facebook,
      _instagram,
      _x,
      _tiktok,
      _youtube,
      _whatsapp,
      _email,
      _googlePlay,
      _webApp,
    ]) {
      c.dispose();
    }
    for (final row in _phones) {
      row.dispose();
    }
    super.dispose();
  }

  // Mirrors the server's rules (https only, '' clears) so the admin sees the
  // problem on the field instead of a generic error after Save.
  String? _validateUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final ok = uri != null && uri.scheme == 'https' && uri.host.contains('.');
    return ok ? null : AppLocalizations.of(context)!.adminSiteSettingsUrlError;
  }

  String? _validatePhone(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required
          ? AppLocalizations.of(context)!.adminSiteSettingsPhoneError
          : null;
    }
    return _phonePattern.hasMatch(text)
        ? null
        : AppLocalizations.of(context)!.adminSiteSettingsPhoneError;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || _emailPattern.hasMatch(text)) return null;
    return AppLocalizations.of(context)!.adminSiteSettingsEmailError;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(adminSiteSettingsControllerProvider.notifier)
          .save(
            SiteSettings(
              facebookUrl: _facebook.text.trim(),
              instagramUrl: _instagram.text.trim(),
              xUrl: _x.text.trim(),
              tiktokUrl: _tiktok.text.trim(),
              youtubeUrl: _youtube.text.trim(),
              whatsappNumber: _whatsapp.text.trim(),
              phones: [
                for (final row in _phones)
                  SitePhone(
                    label: row.label.text.trim(),
                    number: row.number.text.trim(),
                  ),
              ],
              email: _email.text.trim(),
              googlePlayUrl: _googlePlay.text.trim(),
              webAppUrl: _webApp.text.trim(),
            ),
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminSiteSettingsSaved)),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget urlField(
      TextEditingController controller,
      String label,
      IconData icon,
    ) => _Field(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'https://',
          prefixIcon: Icon(icon, size: 20),
        ),
        validator: _validateUrl,
      ),
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          _Section(
            title: l10n.adminSiteSettingsSocialSection,
            children: [
              urlField(_facebook, 'Facebook', Icons.facebook),
              urlField(_instagram, 'Instagram', Icons.camera_alt_outlined),
              urlField(_x, 'X', Icons.alternate_email),
              urlField(_tiktok, 'TikTok', Icons.music_note_outlined),
              urlField(_youtube, 'YouTube', Icons.smart_display_outlined),
            ],
          ),
          _Section(
            title: l10n.adminSiteSettingsContactSection,
            children: [
              _Field(
                child: TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.adminSiteSettingsWhatsapp,
                    hintText: '+20',
                    prefixIcon: const Icon(Icons.chat_outlined, size: 20),
                  ),
                  validator: _validatePhone,
                ),
              ),
              _Field(
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.adminSiteSettingsEmail,
                    prefixIcon: const Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: _validateEmail,
                ),
              ),
            ],
          ),
          _Section(
            title: l10n.adminSiteSettingsPhones,
            children: [
              for (final (index, row) in _phones.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: row.label,
                          decoration: InputDecoration(
                            labelText: l10n.adminSiteSettingsPhoneLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: row.number,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: l10n.adminSiteSettingsPhoneNumber,
                            hintText: '+20',
                          ),
                          validator: (v) => _validatePhone(v, required: true),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.adminSiteSettingsRemovePhone,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _phones.removeAt(index).dispose()),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _phones.length >= _maxPhones
                      ? null
                      : () => setState(
                          () => _phones.add(
                            _PhoneRow(const SitePhone(label: '', number: '')),
                          ),
                        ),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.adminSiteSettingsAddPhone),
                ),
              ),
            ],
          ),
          _Section(
            title: l10n.adminSiteSettingsAppSection,
            children: [
              urlField(
                _googlePlay,
                l10n.adminSiteSettingsGooglePlay,
                Icons.shop_outlined,
              ),
              urlField(_webApp, l10n.adminSiteSettingsWebApp, Icons.language),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    ),
  );
}

/// Caps a field's width: a URL box stretched across a wide admin screen is
/// harder to read than one sized to its content.
class _Field extends StatelessWidget {
  const _Field({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    ),
  );
}
