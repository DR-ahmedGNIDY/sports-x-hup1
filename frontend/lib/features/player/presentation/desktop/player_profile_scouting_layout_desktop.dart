import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/player_about_card.dart';
import '../shared/player_club_card.dart';
import '../shared/player_profile_data.dart';
import '../shared/player_profile_trailing_sections.dart';
import 'basketball_position_section_desktop.dart';
import 'football_position_section_desktop.dart';

/// The desktop Player Profile body: a professional scouting-platform
/// dashboard — a wide hero (photo + identity + quick facts), About and
/// Current Club side by side, the football pitch as a dominant section,
/// then the existing gallery/achievements/social/contact cards. This
/// replaces the old single-column stacked layout entirely; it is not a
/// shared widget with the mobile version because the composition itself
/// (side-by-side vs stacked, hero photo size, header density) differs,
/// not just element sizing.
class PlayerProfileScoutingLayoutDesktop extends StatelessWidget {
  const PlayerProfileScoutingLayoutDesktop({
    super.key,
    required this.profile,
    required this.showContact,
    required this.isOwner,
  });

  final PlayerProfile profile;
  final bool showContact;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final about = buildAboutCard(context, profile);
    final club = buildCurrentClubCard(context, profile);
    final trailing = buildTrailingSections(
      context,
      profile,
      showContact: showContact,
      isOwner: isOwner,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(profile: profile),
        if (about != null || club != null) ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (about != null) Expanded(child: about),
              if (about != null && club != null) const SizedBox(width: 24),
              if (club != null) Expanded(child: club),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FootballPositionSectionDesktop(profile: profile),
        BasketballPositionSectionDesktop(profile: profile),
        for (final section in trailing) ...[section, const SizedBox(height: 16)],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photo = profile.profilePhoto;
    final name = profile.fullName.isEmpty ? l10n.unnamedPlayer : profile.fullName;
    final positionLine = playerPositionSummary(profile);
    final location = [
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');
    final facts = buildQuickFacts(l10n, profile);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: photo != null
                    ? Image.network(photo.secureUrl, fit: BoxFit.cover)
                    : ColoredBox(
                        color: AppColors.profileBg,
                        child: const Icon(Icons.person, size: 88, color: AppColors.greyLight),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: AppColors.profileText, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                if (positionLine.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    positionLine,
                    style: const TextStyle(color: AppColors.profileAccent, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.greyLight),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(color: AppColors.greyLight, fontSize: 14)),
                    ],
                  ),
                ],
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _QuickFactsBar(facts: facts),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFactsBar extends StatelessWidget {
  const _QuickFactsBar({required this.facts});

  final List<QuickFact> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.profileBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Wrap(
        spacing: 36,
        runSpacing: 14,
        children: [for (final fact in facts) _QuickFactItem(fact: fact)],
      ),
    );
  }
}

class _QuickFactItem extends StatelessWidget {
  const _QuickFactItem({required this.fact});

  final QuickFact fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(fact.icon, size: 20, color: AppColors.profileAccent),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fact.label, style: const TextStyle(color: AppColors.greyLight, fontSize: 12)),
            Text(
              fact.value,
              style: const TextStyle(color: AppColors.profileText, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
