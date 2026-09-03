import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/memberships_providers.dart';
import '../../domain/entities/membership.dart';

/// A club's current players, on its public profile.
///
/// The list holds only players whose own profile is public — the backend
/// filters and counts the same set, so this is never "5 of 8" with three
/// hidden. It is therefore the club's *visible* roster rather than its full
/// one, which is the honest thing for a public page to show: belonging to a
/// club is not a way around a player's visibility setting.
///
/// The whole section disappears when there is nobody to list. A club with
/// no members yet has nothing to say here, and an empty "Players (0)"
/// heading on a public profile reads as a club with no players rather than
/// as a feature nobody has used.
class ClubMembersSection extends ConsumerStatefulWidget {
  const ClubMembersSection({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<ClubMembersSection> createState() => _ClubMembersSectionState();
}

class _ClubMembersSectionState extends ConsumerState<ClubMembersSection> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final membersAsync = ref.watch(
      clubMembersProvider((clubId: widget.clubId, page: _page)),
    );

    // Loading and failure still render nothing: this is a supplementary
    // section on someone else's profile, and a spinner or an error box
    // there is worse than its quiet absence. `valueOrNull`, not `value` —
    // the latter rethrows on an AsyncError, which would take the whole
    // profile page down with a side request.
    final page = membersAsync.valueOrNull;
    if (page == null) return const SizedBox.shrink();

    // An empty roster is stated rather than hidden. Vanishing was the right
    // call while this sat under a profile that had other things to show; on
    // a club that has filled nothing in, every section vanished the same way
    // and the visitor was left facing a blank page with no way to tell an
    // empty club from a broken one.
    if (page.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.clubMembersTitle(0), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.clubMembersEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clubMembersTitle(page.total),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final member in page.items) _MemberTile(member: member),
        if (page.total > page.pageSize)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l10n.previousPageLabel,
                onPressed: page.page > 1 ? () => setState(() => _page -= 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                l10n.pageOfPagesLabel(
                  page.page,
                  ((page.total - 1) / page.pageSize).floor() + 1,
                ),
              ),
              IconButton(
                tooltip: l10n.nextPageLabel,
                onPressed: page.hasNextPage ? () => setState(() => _page += 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final ClubMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final player = member.player;
    final name = player.fullName.isEmpty ? l10n.unnamedPlayer : player.fullName;
    final subtitle = [
      player.sport,
      player.position,
      player.country,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => context.push('/players/${player.id}'),
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: player.profilePhotoUrl != null
              ? appImageProvider(
                  player.profilePhotoUrl!,
                  context: context,
                  decodeWidth: AppImageSize.avatarSmall,
                )
              : null,
          child: player.profilePhotoUrl == null
              ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        title: Text(name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
      ),
    );
  }
}
