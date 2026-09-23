import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// The admin-granted verification check mark, shown next to a club's name
/// wherever that name appears — the club's own profile, search results and
/// Home-feed posts.
///
/// Sized off the text it sits beside rather than a fixed constant, so it
/// keeps its proportions in the feed card's compact layout as well as on a
/// full-width profile header.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.feedVerifiedClubTooltip,
      // The brand blue, which is also what the familiar "verified" check
      // reads as everywhere else — no separate token needed for it.
      child: Icon(Icons.verified, size: size, color: AppColors.brandBlue),
    );
  }
}
