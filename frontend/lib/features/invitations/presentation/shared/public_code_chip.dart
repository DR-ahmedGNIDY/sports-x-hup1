import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// A public code — `CLB-000123` or `PLY-000123` — with one-tap copy.
///
/// The code only earns its place on a profile if it can be handed to
/// someone, and on a phone that means the clipboard rather than reading six
/// digits aloud. Whole chip is the tap target: a code beside a separate
/// copy icon gives two targets for one intention.
class PublicCodeChip extends StatelessWidget {
  const PublicCodeChip({super.key, required this.label, required this.code});

  /// What kind of code this is ("Club code" / "Player code") — without it a
  /// bare `CLB-000123` on a profile is a string with no job.
  final String label;

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Tooltip(
      message: l10n.copyCodeTooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: code));
          AppHaptics.light();
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.publicCodeCopiedFeedback)));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                code,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.copy_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
