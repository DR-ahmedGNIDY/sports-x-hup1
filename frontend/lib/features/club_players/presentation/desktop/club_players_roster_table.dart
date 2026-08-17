import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/club_managed_player.dart';
import '../shared/club_player_completeness_chip.dart';
import '../shared/whatsapp_send_button.dart';

/// Below this rendered table width, the Phone column is dropped (release-
/// audit P2: at the 900px Desktop breakpoint floor — minus the sidebar and
/// page padding — 5 flex columns plus a 132px actions column left every
/// column too narrow to read comfortably). Phone is the lowest-priority
/// column to drop: it's still one tap away via the row's own WhatsApp
/// action and the player's profile. This is a `LayoutBuilder` reacting to
/// the table's own available width, not a `MediaQuery`/`AppBreakpoints`
/// check — it doesn't decide Desktop vs. Mobile (this widget is already
/// Desktop-only), just how dense *this* table gets within Desktop.
const _phoneColumnMinWidth = 700.0;

/// Desktop-only roster table: Player / Sport / Position / Status / Phone /
/// Actions columns (Phone hidden below [_phoneColumnMinWidth]). Mobile
/// keeps [ClubManagedPlayerCard] — this is the dedicated wide-screen
/// presentation the roster card list didn't provide. Header and rows share
/// the same column widths so they stay aligned without reaching for
/// [DataTable] (whose fixed row height and lack of hover styling don't fit
/// an avatar + name + icon-action row well).
class ClubPlayersRosterTable extends StatelessWidget {
  const ClubPlayersRosterTable({super.key, required this.players});

  final List<ClubManagedPlayer> players;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showPhone = constraints.maxWidth >= _phoneColumnMinWidth;
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RosterHeaderRow(showPhone: showPhone),
              Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
              for (var i = 0; i < players.length; i++) ...[
                _RosterRow(player: players[i], showPhone: showPhone),
                if (i < players.length - 1)
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RosterHeaderRow extends StatelessWidget {
  const _RosterHeaderRow({required this.showPhone});

  final bool showPhone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.clubPlayersTableColumnPlayer, style: style)),
          Expanded(flex: 2, child: Text(l10n.sportLabel, style: style)),
          Expanded(flex: 2, child: Text(l10n.positionLabel, style: style)),
          Expanded(flex: 2, child: Text(l10n.clubPlayersTableColumnCompleteness, style: style)),
          if (showPhone) Expanded(flex: 2, child: Text(l10n.phoneLabel, style: style)),
          SizedBox(width: 132, child: Text(l10n.clubPlayersTableColumnActions, style: style)),
        ],
      ),
    );
  }
}

enum _RowAction { view, remove }

class _RosterRow extends ConsumerStatefulWidget {
  const _RosterRow({required this.player, required this.showPhone});

  final ClubManagedPlayer player;
  final bool showPhone;

  @override
  ConsumerState<_RosterRow> createState() => _RosterRowState();
}

class _RosterRowState extends ConsumerState<_RosterRow> {
  bool _hovering = false;

  Future<void> _confirmRemove(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clubPlayerRemoveTitle),
        content: Text(l10n.clubPlayerRemoveContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.clubPlayerRemoveConfirm,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(clubPlayersControllerProvider.notifier).removePlayer(widget.player.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubPlayerRemovedMessage)));
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final profile = widget.player.profile;
    final fullName = profile.fullName.isEmpty ? (profile.contact.phone ?? '') : profile.fullName;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: () => context.push('/players/${profile.id}'),
        child: Container(
          color: _hovering ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: profile.profilePhoto != null
                          ? NetworkImage(profile.profilePhoto!.secureUrl)
                          : null,
                      child: profile.profilePhoto == null
                          ? Icon(Icons.person, size: 18, color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: _RosterCellText(profile.sport)),
              Expanded(flex: 2, child: _RosterCellText(profile.position)),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ClubPlayerCompletenessChip(percent: profile.completionPercent),
                ),
              ),
              if (widget.showPhone)
                Expanded(flex: 2, child: _RosterCellText(profile.contact.phone)),
              SizedBox(
                width: 132,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.clubPlayerEditAction,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => context.go('/club/players/${widget.player.userId}/edit'),
                    ),
                    IconButton(
                      tooltip: l10n.clubPlayerResendCredentialsWhatsAppButton,
                      icon: const Icon(Icons.chat_outlined, size: 20),
                      onPressed: () =>
                          resendCredentialsAndOpenWhatsApp(context, ref, widget.player),
                    ),
                    PopupMenuButton<_RowAction>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (action) {
                        switch (action) {
                          case _RowAction.view:
                            context.push('/players/${profile.id}');
                          case _RowAction.remove:
                            _confirmRemove(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _RowAction.view,
                          child: Text(l10n.clubPlayerViewAction),
                        ),
                        PopupMenuItem(
                          value: _RowAction.remove,
                          child: Text(
                            l10n.clubPlayerRemoveAction,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterCellText extends StatelessWidget {
  const _RosterCellText(this.value);

  final String? value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Text(
      hasValue ? value! : '—',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: hasValue ? null : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
