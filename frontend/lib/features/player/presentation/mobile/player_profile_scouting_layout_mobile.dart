import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/fade_slide_in.dart';
import '../shared/player_club_card.dart';
import '../shared/player_hero_card.dart';
import '../shared/player_info_card.dart';
import '../shared/player_profile_data.dart';
import '../shared/player_profile_trailing_sections.dart';
import '../shared/quick_stats_grid.dart';
import 'basketball_position_section_mobile.dart';
import 'football_position_section_mobile.dart';

/// The mobile Player Profile body — a dedicated composition, not a
/// shrunk copy of the desktop dashboard: a portrait hero photo instead
/// of the wide desktop hero, a wrapping quick-stats grid, and every card
/// stacked full-width since there's no room for side-by-side panels on a
/// phone. Section order follows the redesign spec: Hero → Quick Stats →
/// Position → Achievements → Player Information → Current Club →
/// Gallery/Skills/Traits/Social/Contact. [heroActions] (edit/share
/// buttons) is optional so this same widget serves both the owner's
/// preview (which passes them) and the public scouting view (which
/// doesn't — it has its own app-bar actions).
class PlayerProfileScoutingLayoutMobile extends StatelessWidget {
  const PlayerProfileScoutingLayoutMobile({
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

    const stagger = Duration(milliseconds: 60);
    var step = 0;
    Widget staggered(Widget child) {
      final delay = AppMotion.fast + stagger * step;
      step++;
      return FadeSlideIn(delay: delay, child: child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        staggered(PlayerHeroCard(profile: profile, compact: true, actions: heroActions)),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 16),
          staggered(QuickStatsGrid(facts: facts, compact: true)),
        ],
        const SizedBox(height: 16),
        staggered(FootballPositionSectionMobile(profile: profile)),
        staggered(BasketballPositionSectionMobile(profile: profile)),
        if (achievements != null) ...[staggered(achievements), const SizedBox(height: 16)],
        if (info != null) ...[staggered(info), const SizedBox(height: 16)],
        staggered(club),
        const SizedBox(height: 16),
        for (final section in trailing) ...[staggered(section), const SizedBox(height: 16)],
      ],
    );
  }
}
