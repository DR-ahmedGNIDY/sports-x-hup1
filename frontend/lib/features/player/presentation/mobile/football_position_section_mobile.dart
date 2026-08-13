import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/football_position.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/football_pitch_canvas.dart';
import '../shared/football_pitch_frame.dart';
import '../shared/football_position_legend.dart';
import '../shared/football_position_list.dart';

/// Read-only Football Position pitch for the mobile Player Profile /
/// Preview pages. A separate presentation from the desktop version (not
/// a scaled-down copy): a tall vertical aspect ratio so the whole pitch
/// fits on screen without horizontal scrolling, and markers sized for a
/// touch target instead of a mouse pointer.
class FootballPositionSectionMobile extends StatelessWidget {
  const FootballPositionSectionMobile({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!isFootballSport(profile.sport)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final positions = parseFootballPositions(profile.position);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FootballPitchFrame(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FootballPitchHeader(
              title: l10n.footballPositionSectionTitle,
              subtitle: l10n.footballPositionViewHint,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 0.68,
              child: FootballPitchCanvas(positions: positions, markerRadius: 17),
            ),
            const SizedBox(height: 14),
            const FootballPositionLegend(),
          ],
        ),
      ),
    );
  }
}

/// Editable Football Position picker for the mobile Edit Profile page:
/// the pitch on top (tall, fits the screen width), the selectable
/// position list stacked below it instead of beside it — the desktop
/// side-by-side layout doesn't fit a phone width. Same shared
/// `positions`/`onTap`/`onLongPress` state as the desktop builder.
Widget buildFootballPositionEditorMobile(
  BuildContext context, {
  required String? sport,
  required List<String> positions,
  required ValueChanged<String> onTap,
  required ValueChanged<String> onLongPress,
}) {
  if (!isFootballSport(sport)) return const SizedBox.shrink();
  final l10n = AppLocalizations.of(context)!;

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: FootballPitchFrame(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FootballPitchHeader(
            title: l10n.footballPositionSectionTitle,
            subtitle: l10n.footballPositionPickerSubtitle,
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 0.72,
            child: FootballPitchCanvas(
              positions: positions,
              markerRadius: 18,
              editable: true,
              onPositionTap: onTap,
              onPositionLongPress: onLongPress,
            ),
          ),
          const SizedBox(height: 14),
          const FootballPositionLegend(),
          const SizedBox(height: 8),
          Text(
            l10n.footballPositionEditHint,
            style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
          ),
          const SizedBox(height: 18),
          FootballPositionList(positions: positions, onTap: onTap, onLongPress: onLongPress),
        ],
      ),
    ),
  );
}
