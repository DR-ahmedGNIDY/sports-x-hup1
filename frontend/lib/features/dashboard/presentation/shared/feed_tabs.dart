import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home_feed/domain/entities/feed_item.dart';

/// The Home feed's content-type tabs — a purely client-side filter over
/// whatever page is already loaded (the feed endpoint has no `kind` query
/// param), so switching tabs never triggers a new request. `null` means
/// "All".
class FeedTabs extends StatelessWidget {
  const FeedTabs({super.key, required this.value, required this.onChanged});

  final FeedItemKind? value;
  final ValueChanged<FeedItemKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;
    final tabs = <(FeedItemKind?, String)>[
      (null, l10n.homeFeedTabAll),
      (FeedItemKind.photo, l10n.homeFeedTabPhotos),
      (FeedItemKind.video, l10n.homeFeedTabVideos),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (kind, label) = tabs[index];
          final selected = kind == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(kind),
            backgroundColor: colors.surface,
            selectedColor: AppColors.brandBlue,
            labelStyle: TextStyle(
              color: selected ? AppColors.white : colors.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            side: BorderSide(color: colors.borderOnSurface.withValues(alpha: 0.08)),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
