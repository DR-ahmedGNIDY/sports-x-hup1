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
import '../shared/invitations_screen_config.dart';
import '../../../notifications/presentation/shared/push_prompt_card.dart';

/// Both inboxes, for either role — see [InvitationsScreenConfig].
class InvitationsPageMobile extends ConsumerStatefulWidget {
  const InvitationsPageMobile({super.key, required this.config});

  final InvitationsScreenConfig config;

  @override
  ConsumerState<InvitationsPageMobile> createState() => _InvitationsPageMobileState();
}

class _InvitationsPageMobileState extends ConsumerState<InvitationsPageMobile> {
  // Which inbox is showing. Screen-local rather than a provider: it is
  // where the user is looking, not application state, and each list keeps
  // its own page and filter in its own controller regardless.
  InvitationsListKind _kind = InvitationsListKind.received;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = widget.config;
    final listAsync = ref.watch(invitationsListProvider(_kind));

    return AppScaffoldMobile(
      onRefresh: () async {
        ref.invalidate(invitationsListProvider(_kind));
        ref.invalidate(invitationsSummaryProvider);
      },
      actions: [
        IconButton(
          tooltip: config.codeActionLabel(l10n),
          onPressed: () => config.openCodeSheet(context),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PushPromptCard(),
                InvitationsFilterBar(
                  kind: _kind,
                  onKindChanged: (kind) => setState(() => _kind = kind),
                ),
              ],
            ),
          ),
        ),
        listAsync.when(
          data: (page) => page.items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    message: _kind == InvitationsListKind.received
                        ? config.emptyReceived(l10n)
                        : config.emptySent(l10n),
                    // The way out of an empty outbox is to send something;
                    // an empty inbox has no action of its own — nothing you
                    // do makes someone else write to you.
                    actionLabel: _kind == InvitationsListKind.sent
                        ? config.codeActionLabel(l10n)
                        : null,
                    onAction: _kind == InvitationsListKind.sent
                        ? () => config.openCodeSheet(context)
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
