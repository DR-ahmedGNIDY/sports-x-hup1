import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../invitations/application/memberships_providers.dart';
import '../../../invitations/domain/entities/membership.dart';
import '../../domain/entities/player_profile.dart';
import 'player_profile_data.dart';
import 'section_card.dart';

/// The Current Club card — always rendered (unlike the other optional
/// sections on this page), per the redesign spec: a player with no club
/// on file should still see a clear, professional "No Club" state rather
/// than the section vanishing outright.
///
/// Two sources, deliberately ranked. A **membership** is authoritative: a
/// club invited this player (or accepted their request) and the player
/// agreed, so it carries a real club to link to, a logo, a code and a join
/// date. `PlayerProfile.currentClub` is free text the player typed and
/// nobody agreed to; it is the fallback, and only while there is no
/// membership. The two are never merged — showing a typed club name beside
/// a real one would imply they had been reconciled.
Widget buildCurrentClubCard(BuildContext context, PlayerProfile profile) =>
    CurrentClubCard(profile: profile);

class CurrentClubCard extends ConsumerWidget {
  const CurrentClubCard({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // A failed or still-loading membership read falls through to the typed
    // club rather than blocking the card: the section is one line of a
    // profile, not a screen of its own, and a spinner where a club name
    // belongs reads as breakage.
    //
    // `valueOrNull`, not `value` — the latter *rethrows* on an AsyncError,
    // which would turn a failed side request into a broken profile page.
    final membership = ref.watch(playerClubProvider(profile.id)).valueOrNull;
    if (membership != null) {
      return _MembershipState(membership: membership, l10n: l10n);
    }
    return _buildTypedClubCard(context, profile, l10n);
  }
}

Widget _buildTypedClubCard(
  BuildContext context,
  PlayerProfile profile,
  AppLocalizations l10n,
) {
  final club = currentClubInfo(profile);
  final profileColors = context.profileColors;
  return ProfileSectionCard(
    icon: Icons.shield_outlined,
    title: l10n.currentClubLabel,
    child: club == null
        ? _NoClubState(l10n: l10n)
        : Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: profileColors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: profileColors.borderOnSurface.withValues(alpha: 0.08)),
                ),
                child: Icon(Icons.shield_outlined, color: profileColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: TextStyle(
                        color: profileColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (club.status != null) ...[
                      const SizedBox(height: 2),
                      Text(club.status!, style: TextStyle(color: profileColors.textMuted, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
  );
}

/// The card when the player actually belongs to a club. Unlike the typed
/// fallback this one is a real record, so it links to the club's profile
/// and shows the code and the date the relationship started.
class _MembershipState extends StatelessWidget {
  const _MembershipState({required this.membership, required this.l10n});

  final PlayerClubMembership membership;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    final club = membership.club;
    final name = club.name?.isNotEmpty == true ? club.name! : l10n.unnamedClub;
    final subtitle = [
      if (club.location.isNotEmpty) club.location,
      if (membership.joinedAt case final joinedAt?)
        l10n.membershipJoinedOn(_formatDate(joinedAt)),
    ].join(' · ');

    return ProfileSectionCard(
      icon: Icons.shield_outlined,
      title: l10n.currentClubLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => context.push('/clubs/${club.id}'),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: profileColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: profileColors.borderOnSurface.withValues(alpha: 0.08),
                ),
                image: club.logoUrl != null
                    ? DecorationImage(
                        image: appImageProvider(
                          club.logoUrl!,
                          context: context,
                          decodeWidth: AppImageSize.avatarSmall,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: club.logoUrl == null
                  ? Icon(Icons.shield_outlined, color: profileColors.accent, size: 22)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: profileColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: profileColors.textMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: profileColors.textMuted),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _NoClubState extends StatelessWidget {
  const _NoClubState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: profileColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: profileColors.borderOnSurface.withValues(alpha: 0.08),
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(Icons.shield_moon_outlined, color: profileColors.textMuted, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.noClubTitle,
                style: TextStyle(color: profileColors.text, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(l10n.noClubSubtitle, style: TextStyle(color: profileColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
