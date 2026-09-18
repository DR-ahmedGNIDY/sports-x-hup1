import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../player/presentation/shared/section_card.dart';
import '../application/coach_providers.dart';
import '../data/coach_repository.dart';
import '../domain/coach_models.dart';
import 'shared/coach_widgets.dart';

/// `/club/coaches` — the club account's coaching staff: who is on it, what
/// each coach may do, inviting by code, and requests from coaches. Club
/// account only: managing staff is never delegated to a coach.
class ClubCoachesPage extends ConsumerWidget {
  const ClubCoachesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    void refreshAll() {
      ref
        ..invalidate(clubStaffProvider)
        ..invalidate(coachInvitationsProvider(true))
        ..invalidate(coachInvitationsProvider(false));
    }

    return CoachPageBody(
      onRefresh: () async {
        refreshAll();
        await ref.read(clubStaffProvider.future);
      },
      children: [
        ProfileSectionCard(
          icon: Icons.sports,
          title: l10n.clubCoachesTitle,
          child: ref
              .watch(clubStaffProvider)
              .when(
                data: (staff) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (staff.isEmpty)
                      Text(
                        l10n.clubNoCoachesYet,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    for (final member in staff)
                      _StaffTile(member: member, onChanged: refreshAll),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(l10n.clubInviteCoachByCode),
                        onPressed: () async {
                          final sent = await showCodeInvitationDialog(
                            context,
                            title: l10n.clubInviteCoachByCode,
                            codeLabel: l10n.coachCodeLabel,
                            codeHint: 'COA-000123',
                            submit: (code, message) => ref
                                .read(coachRepositoryProvider)
                                .inviteCoach(code, message: message),
                          );
                          if (sent && context.mounted) {
                            refreshAll();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.invitationSentFeedback),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  message: e is AppException ? e.message : null,
                  onRetry: refreshAll,
                ),
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSectionCard(
          icon: Icons.mail_outline,
          title: l10n.invitationsTitle,
          child: CoachInvitationsLists(
            viewerIsClub: true,
            onChanged: () => ref.invalidate(clubStaffProvider),
          ),
        ),
      ],
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.member, required this.onChanged});

  final StaffMember member;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final coach = member.coach;
    final name = (coach?.fullName.isNotEmpty ?? false)
        ? coach!.fullName
        : l10n.coachUnnamed;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CoachAvatar(url: coach?.profilePhotoUrl),
        title: Text(name),
        subtitle: Text(
          l10n.clubCoachPermissionCount(member.permissions.length),
        ),
        onTap: coach == null
            ? null
            : () => context.push('/coaches/${coach.id}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'permissions') {
              await showDialog<void>(
                context: context,
                builder: (_) => _PermissionsDialog(
                  member: member,
                  coachName: name,
                  onSaved: onChanged,
                ),
              );
              return;
            }
            final ok = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.clubRemoveCoachConfirm(name)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.cancelLabel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.clubRemoveCoach),
                  ),
                ],
              ),
            );
            if (ok != true || !context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref
                  .read(coachRepositoryProvider)
                  .removeCoach(member.membershipId);
              onChanged();
            } on AppException catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(e.message)));
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'permissions',
              child: Text(l10n.clubEditPermissions),
            ),
            PopupMenuItem(value: 'remove', child: Text(l10n.clubRemoveCoach)),
          ],
        ),
      ),
    );
  }
}

class _PermissionsDialog extends ConsumerStatefulWidget {
  const _PermissionsDialog({
    required this.member,
    required this.coachName,
    required this.onSaved,
  });

  final StaffMember member;
  final String coachName;
  final VoidCallback onSaved;

  @override
  ConsumerState<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends ConsumerState<_PermissionsDialog> {
  late final Set<CoachPermission> _selected = {
    ...widget.member.permissions,
    CoachPermission.viewSquad,
  };
  bool _busy = false;
  String? _error;

  bool get _all => _selected.length == CoachPermission.values.length;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(coachRepositoryProvider)
          .setPermissions(widget.member.membershipId, _selected.toList());
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
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
      title: Text(l10n.clubPermissionsFor(widget.coachName)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.clubAllPermissions,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                value: _all,
                onChanged: (on) => setState(() {
                  _selected
                    ..clear()
                    ..addAll(on ? CoachPermission.values : const []);
                  _selected.add(CoachPermission.viewSquad);
                }),
              ),
              const Divider(),
              for (final p in CoachPermission.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(coachPermissionLabel(l10n, p)),
                  value: _selected.contains(p),
                  // Being on the staff *is* seeing the squad.
                  onChanged: p == CoachPermission.viewSquad
                      ? null
                      : (on) => setState(
                          () => on == true
                              ? _selected.add(p)
                              : _selected.remove(p),
                        ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l10n.saveLabel),
        ),
      ],
    );
  }
}
