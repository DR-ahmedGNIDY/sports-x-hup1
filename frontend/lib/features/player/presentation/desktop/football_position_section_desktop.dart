import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/football_position.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/football_pitch_canvas.dart';
import '../shared/football_pitch_frame.dart';
import '../shared/football_position_legend.dart';
import '../shared/football_position_list.dart';

/// Read-only Football Position pitch for the desktop Player Profile /
/// Preview pages — large and prominent per the design spec, not squeezed
/// into a small card.
class FootballPositionSectionDesktop extends StatelessWidget {
  const FootballPositionSectionDesktop({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!isFootballSport(profile.sport)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final positions = parseFootballPositions(profile.position);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FootballPitchFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FootballPitchHeader(
              title: l10n.footballPositionSectionTitle,
              subtitle: l10n.footballPositionViewHint,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 560,
              child: FootballPitchCanvas(positions: positions, markerRadius: 26),
            ),
            const SizedBox(height: 18),
            const FootballPositionLegend(),
          ],
        ),
      ),
    );
  }
}

/// Editable Football Position picker for the desktop Edit Profile page:
/// a large pitch beside a scrollable list of every position, mirroring a
/// scouting-platform position selector. The `positions`/`onTap`/
/// `onLongPress` state is owned by [ProfileDetailsForm]
/// (`../shared/profile_details_form.dart`) — this widget is presentation
/// only.
Widget buildFootballPositionEditorDesktop(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FootballPitchHeader(
            title: l10n.footballPositionSectionTitle,
            subtitle: l10n.footballPositionPickerSubtitle,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 520,
                      child: FootballPitchCanvas(
                        positions: positions,
                        markerRadius: 24,
                        editable: true,
                        onPositionTap: onTap,
                        onPositionLongPress: onLongPress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FootballPositionLegend(),
                    const SizedBox(height: 10),
                    Text(
                      l10n.footballPositionEditHint,
                      style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                height: 590,
                child: SingleChildScrollView(
                  child: FootballPositionList(
                    positions: positions,
                    onTap: onTap,
                    onLongPress: onLongPress,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
