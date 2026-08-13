import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import '../shared/player_about_card.dart';
import '../shared/player_club_card.dart';
import '../shared/player_profile_data.dart';
import '../shared/player_profile_trailing_sections.dart';
import 'basketball_position_section_mobile.dart';
import 'football_position_section_mobile.dart';

/// The mobile Player Profile body — a dedicated composition, not a
/// shrunk copy of the desktop dashboard: a compact horizontal header
/// (circular photo + identity) instead of the big hero photo, a 2-column
/// quick-facts grid instead of one wide bar, and every card stacked
/// full-width since there's no room for side-by-side panels on a phone.
class PlayerProfileScoutingLayoutMobile extends StatelessWidget {
  const PlayerProfileScoutingLayoutMobile({
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
    final l10n = AppLocalizations.of(context)!;
    final facts = buildQuickFacts(l10n, profile);
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
        _CompactHeader(profile: profile),
        if (facts.isNotEmpty) ...[const SizedBox(height: 16), _QuickFactsGrid(facts: facts)],
        if (about != null) ...[const SizedBox(height: 16), about],
        if (club != null) ...[const SizedBox(height: 16), club],
        const SizedBox(height: 16),
        FootballPositionSectionMobile(profile: profile),
        BasketballPositionSectionMobile(profile: profile),
        for (final section in trailing) ...[section, const SizedBox(height: 16)],
      ],
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.profile});

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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.profileBg,
            backgroundImage: photo != null ? NetworkImage(photo.secureUrl) : null,
            child: photo == null ? const Icon(Icons.person, size: 36, color: AppColors.greyLight) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: AppColors.profileText, fontSize: 19, fontWeight: FontWeight.w800),
                ),
                if (positionLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    positionLine,
                    style: const TextStyle(color: AppColors.profileAccent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(location, style: const TextStyle(color: AppColors.greyLight, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFactsGrid extends StatelessWidget {
  const _QuickFactsGrid({required this.facts});

  final List<QuickFact> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2.6,
        ),
        itemCount: facts.length,
        itemBuilder: (context, index) => _QuickFactTile(fact: facts[index]),
      ),
    );
  }
}

class _QuickFactTile extends StatelessWidget {
  const _QuickFactTile({required this.fact});

  final QuickFact fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(fact.icon, size: 18, color: AppColors.profileAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fact.label, style: const TextStyle(color: AppColors.greyLight, fontSize: 11)),
              Text(
                fact.value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.profileText, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
