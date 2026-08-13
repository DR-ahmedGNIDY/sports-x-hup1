import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/basketball_position.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/basketball_court_canvas.dart';
import '../shared/basketball_position_legend.dart';
import '../shared/basketball_position_list.dart';
import '../shared/football_pitch_frame.dart';

/// Read-only Basketball Position court for the mobile Player Profile /
/// Preview pages. A separate presentation from the desktop version (not
/// a scaled-down copy): a compact landscape aspect ratio so the whole
/// court fits on screen width without excessive vertical scrolling, and
/// markers sized for a touch target instead of a mouse pointer.
class BasketballPositionSectionMobile extends StatelessWidget {
  const BasketballPositionSectionMobile({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!isBasketballSport(profile.sport)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final positions = parseBasketballPositions(profile.position);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FootballPitchFrame(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FootballPitchHeader(
              title: l10n.basketballPositionSectionTitle,
              subtitle: l10n.basketballPositionViewHint,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.45,
              child: BasketballCourtCanvas(positions: positions, markerRadius: 17),
            ),
            const SizedBox(height: 14),
            const BasketballPositionLegend(),
          ],
        ),
      ),
    );
  }
}

/// Editable Basketball Position picker for the mobile Edit Profile page:
/// the court on top (compact, fits the screen width), the selectable
/// position list stacked below it instead of beside it — the desktop
/// side-by-side layout doesn't fit a phone width. Same shared
/// `positions`/`onTap`/`onLongPress` state as the desktop builder.
Widget buildBasketballPositionEditorMobile(
  BuildContext context, {
  required String? sport,
  required List<String> positions,
  required ValueChanged<String> onTap,
  required ValueChanged<String> onLongPress,
}) {
  if (!isBasketballSport(sport)) return const SizedBox.shrink();
  final l10n = AppLocalizations.of(context)!;

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: FootballPitchFrame(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FootballPitchHeader(
            title: l10n.basketballPositionSectionTitle,
            subtitle: l10n.basketballPositionPickerSubtitle,
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.45,
            child: BasketballCourtCanvas(
              positions: positions,
              markerRadius: 18,
              editable: true,
              onPositionTap: onTap,
              onPositionLongPress: onLongPress,
            ),
          ),
          const SizedBox(height: 14),
          const BasketballPositionLegend(),
          const SizedBox(height: 8),
          Text(
            l10n.basketballPositionEditHint,
            style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
          ),
          const SizedBox(height: 18),
          BasketballPositionList(positions: positions, onTap: onTap, onLongPress: onLongPress),
        ],
      ),
    ),
  );
}
