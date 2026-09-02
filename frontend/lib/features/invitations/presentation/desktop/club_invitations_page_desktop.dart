import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../shared/invitation_card.dart';
import '../shared/invitations_filter_bar.dart';
import '../shared/invitations_pagination.dart';
import '../shared/invite_by_code_sheet.dart';

class ClubInvitationsPageDesktop extends ConsumerStatefulWidget {
  const ClubInvitationsPageDesktop({super.key});

  @override
  ConsumerState<ClubInvitationsPageDesktop> createState() =>
      _ClubInvitationsPageDesktopState();
}

class _ClubInvitationsPageDesktopState
    extends ConsumerState<ClubInvitationsPageDesktop> {
  InvitationsListKind _kind = InvitationsListKind.received;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(invitationsListProvider(_kind));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.invitationsTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showInviteByCodeSheet(context),
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: Text(l10n.inviteByCodeTitle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              InvitationsFilterBar(
                kind: _kind,
                onKindChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: listAsync.when(
                  data: (page) => page.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const EmptyStateIllustration(
                                variant: EmptyStateVariant.noData,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _kind == InvitationsListKind.received
                                    ? l10n.invitationsEmptyReceived
                                    : l10n.invitationsEmptySent,
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            for (final invitation in page.items)
                              InvitationCard(invitation: invitation, kind: _kind),
                            InvitationsPagination(page: page, kind: _kind),
                          ],
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(
                    onRetry: () => ref.invalidate(invitationsListProvider(_kind)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
