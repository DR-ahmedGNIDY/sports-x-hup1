import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../invitations/domain/entities/invitation.dart';
import '../../../invitations/presentation/shared/invitation_status_chip.dart';
import '../../application/coach_providers.dart';
import '../../data/coach_repository.dart';
import '../../domain/coach_models.dart';

String coachPermissionLabel(AppLocalizations l10n, CoachPermission p) =>
    switch (p) {
      CoachPermission.viewSquad => l10n.coachPermViewSquad,
      CoachPermission.viewPlayerContacts => l10n.coachPermViewContacts,
      CoachPermission.manageCalendar => l10n.coachPermManageCalendar,
      CoachPermission.manageLineup => l10n.coachPermManageLineup,
      CoachPermission.invitePlayers => l10n.coachPermInvitePlayers,
      CoachPermission.createPlayers => l10n.coachPermCreatePlayers,
      CoachPermission.manageClubPlayers => l10n.coachPermManagePlayers,
      CoachPermission.editClubProfile => l10n.coachPermEditClubProfile,
      CoachPermission.removeMembers => l10n.coachPermRemoveMembers,
    };

/// A round photo with a person/club glyph when there is none.
class CoachAvatar extends StatelessWidget {
  const CoachAvatar({
    super.key,
    this.url,
    this.radius = 22,
    this.fallbackIcon = Icons.sports,
  });

  final String? url;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.surfaceContainerHighest,
      backgroundImage: url != null
          ? appImageProvider(
              url!,
              context: context,
              decodeWidth: radius > 40
                  ? AppImageSize.avatarLarge
                  : AppImageSize.avatarSmall,
            )
          : null,
      child: url == null
          ? Icon(
              fallbackIcon,
              size: radius,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}

/// Asks for a public code (and an optional note), then runs [submit] with
/// them. Server errors — unknown code, already on staff, already pending —
/// are shown inside the dialog so the user can correct the code in place.
/// Resolves `true` once [submit] succeeded.
Future<bool> showCodeInvitationDialog(
  BuildContext context, {
  required String title,
  required String codeLabel,
  required String codeHint,
  required Future<void> Function(String code, String? message) submit,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _CodeInvitationDialog(
      title: title,
      codeLabel: codeLabel,
      codeHint: codeHint,
      submit: submit,
    ),
  );
  return result ?? false;
}

class _CodeInvitationDialog extends StatefulWidget {
  const _CodeInvitationDialog({
    required this.title,
    required this.codeLabel,
    required this.codeHint,
    required this.submit,
  });

  final String title;
  final String codeLabel;
  final String codeHint;
  final Future<void> Function(String code, String? message) submit;

  @override
  State<_CodeInvitationDialog> createState() => _CodeInvitationDialogState();
}

class _CodeInvitationDialogState extends State<_CodeInvitationDialog> {
  final _code = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = _message.text.trim();
      await widget.submit(code, message.isEmpty ? null : message);
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: widget.codeLabel,
                hintText: widget.codeHint,
              ),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _message,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: l10n.invitationMessageLabel,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.coachSendLabel),
        ),
      ],
    );
  }
}

/// One club↔coach invitation, shown from either side: a coach sees the
/// club, a club sees the coach. Actions are exactly the ones the server
/// said it will honour for this viewer (canAccept/canReject/canCancel).
class CoachInvitationTile extends ConsumerStatefulWidget {
  const CoachInvitationTile({
    super.key,
    required this.invitation,
    required this.viewerIsClub,
    this.onChanged,
  });

  final CoachInvitation invitation;
  final bool viewerIsClub;
  final VoidCallback? onChanged;

  @override
  ConsumerState<CoachInvitationTile> createState() =>
      _CoachInvitationTileState();
}

class _CoachInvitationTileState extends ConsumerState<CoachInvitationTile> {
  bool _busy = false;

  Future<void> _run(String action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(coachRepositoryProvider)
          .respond(widget.invitation.id, action);
      widget.onChanged?.call();
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inv = widget.invitation;
    final String title;
    final String? subtitle;
    final String? photo;
    if (widget.viewerIsClub) {
      title = (inv.coach?.fullName.isNotEmpty ?? false)
          ? inv.coach!.fullName
          : l10n.coachUnnamed;
      subtitle = inv.coach?.headline;
      photo = inv.coach?.profilePhotoUrl;
    } else {
      title = inv.club?.name ?? l10n.coachUnnamedClub;
      subtitle = inv.club?.location;
      photo = inv.club?.logoUrl;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CoachAvatar(
                  url: photo,
                  fallbackIcon: widget.viewerIsClub
                      ? Icons.sports
                      : Icons.shield_outlined,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                InvitationStatusChip(status: inv.status),
              ],
            ),
            if (inv.message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(inv.message!),
            ],
            if (inv.canAccept || inv.canReject || inv.canCancel) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                children: [
                  if (inv.canReject)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _run('reject'),
                      child: Text(l10n.invitationRejectLabel),
                    ),
                  if (inv.canAccept)
                    FilledButton(
                      onPressed: _busy ? null : () => _run('accept'),
                      child: Text(l10n.invitationAcceptLabel),
                    ),
                  if (inv.canCancel)
                    TextButton(
                      onPressed: _busy ? null : () => _run('cancel'),
                      child: Text(l10n.invitationCancelInvitationLabel),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Received + sent club↔coach invitations as two stacked lists.
class CoachInvitationsLists extends ConsumerWidget {
  const CoachInvitationsLists({
    super.key,
    required this.viewerIsClub,
    this.onChanged,
  });

  final bool viewerIsClub;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    void refresh() {
      ref
        ..invalidate(coachInvitationsProvider(true))
        ..invalidate(coachInvitationsProvider(false));
      onChanged?.call();
    }

    Widget list(bool received) => ref
        .watch(coachInvitationsProvider(received))
        .when(
          data: (items) {
            final visible = [
              for (final i in items)
                if (i.status == InvitationStatus.pending || received) i,
            ];
            if (visible.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  received
                      ? l10n.coachNoReceivedInvitations
                      : l10n.coachNoSentInvitations,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final invitation in visible)
                  CoachInvitationTile(
                    invitation: invitation,
                    viewerIsClub: viewerIsClub,
                    onChanged: refresh,
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(e is AppException ? e.message : '$e'),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.invitationsReceivedTab,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        list(true),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.coachPendingSentTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        list(false),
      ],
    );
  }
}

/// A centred, width-capped scroll page — the shape every coach screen uses
/// on both phone and desktop.
class CoachPageBody extends StatelessWidget {
  const CoachPageBody({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
