import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/basketball_position.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/basketball_court_canvas.dart';
import '../shared/basketball_position_legend.dart';
import '../shared/basketball_position_list.dart';
import '../shared/football_pitch_frame.dart';

/// Read-only Basketball Position court for the desktop Player Profile /
/// Preview pages — large and prominent per the design spec, not squeezed
/// into a small card.
class BasketballPositionSectionDesktop extends StatelessWidget {
  const BasketballPositionSectionDesktop({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!isBasketballSport(profile.sport)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final positions = parseBasketballPositions(profile.position);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FootballPitchFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FootballPitchHeader(
              title: l10n.basketballPositionSectionTitle,
              subtitle: l10n.basketballPositionViewHint,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 380,
              child: BasketballCourtCanvas(positions: positions, markerRadius: 26),
            ),
            const SizedBox(height: 18),
            const BasketballPositionLegend(),
          ],
        ),
      ),
    );
  }
}

/// Editable Basketball Position picker for the desktop Edit Profile page:
/// a large court beside a scrollable list of every position, mirroring a
/// scouting-platform position selector. The `positions`/`onTap`/
/// `onLongPress` state is owned by [ProfileDetailsForm]
/// (`../shared/profile_details_form.dart`) — this widget is presentation
/// only.
Widget buildBasketballPositionEditorDesktop(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FootballPitchHeader(
            title: l10n.basketballPositionSectionTitle,
            subtitle: l10n.basketballPositionPickerSubtitle,
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
                      height: 360,
                      child: BasketballCourtCanvas(
                        positions: positions,
                        markerRadius: 24,
                        editable: true,
                        onPositionTap: onTap,
                        onPositionLongPress: onLongPress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const BasketballPositionLegend(),
                    const SizedBox(height: 10),
                    Text(
                      l10n.basketballPositionEditHint,
                      style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                height: 420,
                child: SingleChildScrollView(
                  child: BasketballPositionList(
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
