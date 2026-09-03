import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/social_link.dart';

/// Social links (Instagram, YouTube, X, etc.) with add/edit/delete.
class SocialLinksSection extends ConsumerWidget {
  const SocialLinksSection({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {SocialLink? existing}) {
    return showDialog(
      context: context,
      builder: (_) => _SocialLinkDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links =
        ref.watch(playerProfileControllerProvider).valueOrNull?.socialLinks ?? const [];
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.socialLinksTitle, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              tooltip: l10n.addSocialLinkTooltip,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _openForm(context, ref),
            ),
          ],
        ),
        if (links.isEmpty) Text(l10n.noSocialLinksYet),
        for (final link in links)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(link.platform),
            subtitle: Text(link.url),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.editLabel,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openForm(context, ref, existing: link),
                ),
                IconButton(
                  tooltip: l10n.deleteLabel,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(playerProfileControllerProvider.notifier)
                      .deleteSocialLink(link.id),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SocialLinkDialog extends ConsumerStatefulWidget {
  const _SocialLinkDialog({this.existing});

  final SocialLink? existing;

  @override
  ConsumerState<_SocialLinkDialog> createState() => _SocialLinkDialogState();
}

class _SocialLinkDialogState extends ConsumerState<_SocialLinkDialog> {
  late final _platform = TextEditingController(text: widget.existing?.platform ?? '');
  late final _url = TextEditingController(text: widget.existing?.url ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _platform.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_platform.text.trim().isEmpty || _url.text.trim().isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.socialLinkValidation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(playerProfileControllerProvider.notifier);
      if (widget.existing != null) {
        await notifier.updateSocialLink(
          widget.existing!.id,
          platform: _platform.text.trim(),
          url: _url.text.trim(),
        );
      } else {
        await notifier.addSocialLink(
          platform: _platform.text.trim(),
          url: _url.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing != null ? l10n.editSocialLinkTitle : l10n.addSocialLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _platform,
            decoration: InputDecoration(
              labelText: l10n.platformLabel,
              hintText: l10n.platformHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: l10n.urlLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.saveLabel),
        ),
      ],
    );
  }
}
