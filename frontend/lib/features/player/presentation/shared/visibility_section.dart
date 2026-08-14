import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/player_enums.dart';

/// Binary Public/Private toggle — no tiered visibility in V1.
class VisibilitySection extends ConsumerWidget {
  // [showTitle] defaults to true for the original Dashboard-card usage,
  // which had no outer heading of its own. Pass false when the caller
  // already renders a title around this widget (e.g. inside a
  // `ProfileSectionCard`) so it isn't printed twice.
  const VisibilitySection({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileControllerProvider).value;
    final isPublic = profile?.visibility == ProfileVisibility.public;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(l10n.visibilityTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
        ],
        Text(
          isPublic ? l10n.visibilityPublicDesc : l10n.visibilityPrivateDesc,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.publicProfileLabel),
          value: isPublic,
          onChanged: profile == null
              ? null
              : (value) => ref
                    .read(playerProfileControllerProvider.notifier)
                    .setVisibility(
                      value ? ProfileVisibility.public : ProfileVisibility.private,
                    ),
        ),
      ],
    );
  }
}
