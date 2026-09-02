import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/basketball_position.dart';
import '../../domain/entities/football_position.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/fade_slide_in.dart';
import '../shared/player_club_card.dart';
import '../shared/player_hero_card.dart';
import '../shared/player_info_card.dart';
import '../shared/player_profile_data.dart';
import '../shared/owner_account_section.dart';
import '../shared/player_profile_trailing_sections.dart';
import '../shared/quick_stats_grid.dart';
import 'basketball_position_section_desktop.dart';
import 'football_position_section_desktop.dart';

/// The desktop Player Profile body: a professional scouting-platform
/// dashboard — a wide photo hero, a full-width quick-stats row, then a
/// two-column grid (Position on the left; Achievements, Player
/// Information, and Current Club stacked on the right) so desktop space
/// is actually used instead of just stretching the mobile column wider,
/// then the existing gallery/skills/traits/social/contact cards
/// full-width at the bottom. Not a shared widget with the mobile version
/// because the composition itself (grid vs stack, hero photo size,
/// header density) differs, not just element sizing.
class PlayerProfileScoutingLayoutDesktop extends StatelessWidget {
  const PlayerProfileScoutingLayoutDesktop({
    super.key,
    required this.profile,
    required this.showContact,
    required this.isOwner,
    this.heroActions,
  });

  final PlayerProfile profile;
  final bool showContact;
  final bool isOwner;
  final Widget? heroActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final facts = buildQuickFacts(l10n, profile);
    final achievements = buildAchievementsSection(context, profile);
    final info = buildPlayerInfoCard(context, profile);
    final club = buildCurrentClubCard(context, profile);
    final trailing = buildTrailingSections(
      context,
      profile,
      showContact: showContact,
      isOwner: isOwner,
    );
    final hasFootball = isFootballSport(profile.sport);
    final hasBasketball = isBasketballSport(profile.sport);

    const stagger = Duration(milliseconds: 60);
    var step = 0;
    Widget staggered(Widget child) {
      final delay = AppMotion.fast + stagger * step;
      step++;
      return FadeSlideIn(delay: delay, child: child);
    }

    final rightColumn = <Widget>[?achievements, ?info, club];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        staggered(PlayerHeroCard(profile: profile, actions: heroActions)),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 24),
          staggered(QuickStatsGrid(facts: facts)),
        ],
        if (isOwner) ...[
          const SizedBox(height: 24),
          staggered(OwnerAccountSection(publicCode: profile.publicCode)),
        ],
        if (hasFootball || hasBasketball) ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: staggered(
                  Column(
                    children: [
                      FootballPositionSectionDesktop(profile: profile),
                      BasketballPositionSectionDesktop(profile: profile),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: staggered(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < rightColumn.length; i++) ...[
                        rightColumn[i],
                        if (i != rightColumn.length - 1) const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 24),
          for (final section in rightColumn) ...[staggered(section), const SizedBox(height: 16)],
        ],
        const SizedBox(height: 8),
        for (final section in trailing) ...[staggered(section), const SizedBox(height: 16)],
      ],
    );
  }
}
