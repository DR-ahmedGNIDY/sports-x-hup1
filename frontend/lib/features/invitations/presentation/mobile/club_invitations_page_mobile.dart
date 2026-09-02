import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_empty_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../shared/invitation_card.dart';
import '../shared/invitations_filter_bar.dart';
import '../shared/invitations_pagination.dart';
import '../shared/invite_by_code_sheet.dart';

class ClubInvitationsPageMobile extends ConsumerStatefulWidget {
  const ClubInvitationsPageMobile({super.key});

  @override
  ConsumerState<ClubInvitationsPageMobile> createState() =>
      _ClubInvitationsPageMobileState();
}

class _ClubInvitationsPageMobileState
    extends ConsumerState<ClubInvitationsPageMobile> {
  // Which inbox is showing. Screen-local rather than a provider: it is
  // where the user is looking, not application state, and each list keeps
  // its own page and filter in its own controller regardless.
  InvitationsListKind _kind = InvitationsListKind.received;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(invitationsListProvider(_kind));

    return AppScaffoldMobile(
      onRefresh: () async {
        ref.invalidate(invitationsListProvider(_kind));
        ref.invalidate(invitationsSummaryProvider);
      },
      actions: [
        IconButton(
          tooltip: l10n.inviteByCodeTitle,
          onPressed: () => showInviteByCodeSheet(context),
          icon: const Icon(Icons.qr_code_2_outlined),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: InvitationsFilterBar(
              kind: _kind,
              onKindChanged: (kind) => setState(() => _kind = kind),
            ),
          ),
        ),
        listAsync.when(
          data: (page) => page.items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    message: _kind == InvitationsListKind.received
                        ? l10n.invitationsEmptyReceived
                        : l10n.invitationsEmptySent,
                    // The way out of an empty outbox is to send one; an
                    // empty inbox has no action of its own — nothing a club
                    // does makes a player write to it.
                    actionLabel: _kind == InvitationsListKind.sent
                        ? l10n.inviteByCodeTitle
                        : null,
                    onAction: _kind == InvitationsListKind.sent
                        ? () => showInviteByCodeSheet(context)
                        : null,
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.list(
                    children: [
                      for (final invitation in page.items)
                        InvitationCard(invitation: invitation, kind: _kind),
                      InvitationsPagination(page: page, kind: _kind),
                    ],
                  ),
                ),
          loading: () => const SliverToBoxAdapter(
            child: AppSkeletonList(itemCount: 4, itemHeight: 140),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () => ref.invalidate(invitationsListProvider(_kind)),
            ),
          ),
        ),
      ],
    );
  }
}
