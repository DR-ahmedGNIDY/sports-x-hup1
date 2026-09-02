import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_install.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/push_controller.dart';

/// The one place the app asks to send notifications to the phone.
///
/// **Where it appears matters more than how it looks.** A browser grants
/// one permission prompt, and a refusal is close to permanent — so this is
/// never shown on first load. It sits at the top of the Notifications and
/// Invitations screens: someone reading an invitation has just discovered
/// the thing the permission is for, which is the only moment the ask
/// explains itself.
///
/// It renders nothing at all unless there is something to offer: already
/// enabled, already refused, or a browser and server that cannot do it
/// between them all show an empty box, not an apology.
class PushPromptCard extends ConsumerStatefulWidget {
  const PushPromptCard({super.key});

  @override
  ConsumerState<PushPromptCard> createState() => _PushPromptCardState();
}

class _PushPromptCardState extends ConsumerState<PushPromptCard> {
  bool _busy = false;

  /// Dismissed for this screen only, and not persisted: the card is already
  /// invisible in every state except "we could ask", and someone who taps
  /// away today may well want it next week.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final offer = ref.watch(pushOfferProvider).valueOrNull;
    if (offer == null ||
        offer == PushOffer.enabled ||
        offer == PushOffer.denied ||
        offer == PushOffer.unavailable) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final needsInstall = offer == PushOffer.needsInstall;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.pushPromptTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.cancelLabel,
                  onPressed: () => setState(() => _dismissed = true),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // The iOS case gets its own sentence rather than the generic
              // one: "install first" is a different instruction from
              // "allow", and conflating them is how an iPhone user ends up
              // silently receiving nothing.
              needsInstall ? l10n.pushPromptInstallBody : l10n.pushPromptBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilledButton(
                      onPressed: needsInstall ? _install : _enable,
                      child: Text(
                        needsInstall
                            ? l10n.pushPromptInstallAction
                            : l10n.pushPromptEnableAction,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enable() async {
    AppHaptics.light();
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final enabled = await ref.read(pushControllerProvider).enable();
    if (!mounted) return;
    setState(() => _busy = false);

    if (enabled) {
      AppHaptics.success();
      ref.invalidate(pushOfferProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.pushEnabledFeedback)));
    } else {
      // Refused, or the browser declined. Not an error worth an alarm —
      // and the card will not come back, because the offer is now `denied`.
      messenger.showSnackBar(SnackBar(content: Text(l10n.pushNotEnabledFeedback)));
      ref.invalidate(pushOfferProvider);
    }
  }

  Future<void> _install() async {
    AppHaptics.light();
    final offer = installOffer();
    if (offer == InstallOffer.prompt) {
      // Chromium captured a real prompt — replay it straight from this tap.
      await promptInstall();
      ref.invalidate(pushOfferProvider);
      return;
    }
    // iOS: there is no prompt to replay. All the app can do is say how.
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pushPromptInstallAction),
        content: Text(l10n.pushInstallInstructions),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backLabel),
          ),
        ],
      ),
    );
  }
}
