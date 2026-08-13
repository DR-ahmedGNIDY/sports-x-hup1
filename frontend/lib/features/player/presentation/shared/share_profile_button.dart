import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Copies the public profile link to the clipboard — no backend endpoint
/// exists for sharing, so this is the smallest honest implementation of
/// "Share Profile" the current app can support. `compact` picks between
/// a labeled button (desktop header) and an icon-only one (mobile
/// header, where space is tight).
class ShareProfileButton extends StatelessWidget {
  const ShareProfileButton({super.key, required this.playerId, this.compact = false});

  final String playerId;
  final bool compact;

  Future<void> _share(BuildContext context) async {
    final origin = Uri.base.origin;
    final link = '$origin/#/players/$playerId';
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.shareProfileLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (compact) {
      return IconButton(
        tooltip: l10n.shareProfileLabel,
        icon: const Icon(Icons.ios_share_outlined),
        onPressed: () => _share(context),
      );
    }
    return TextButton.icon(
      onPressed: () => _share(context),
      icon: const Icon(Icons.ios_share_outlined),
      label: Text(l10n.shareProfileLabel),
    );
  }
}
