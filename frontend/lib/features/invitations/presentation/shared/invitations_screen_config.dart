import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'invite_by_code_sheet.dart';
import 'join_by_code_sheet.dart';

/// What differs between the Club's inbox and the Player's.
///
/// The screens themselves are the same screen — two tabs, a status filter,
/// a paginated list of cards — because an invitation is one object seen
/// from two ends, and the card already renders itself from the viewer's
/// side. What actually differs is three strings and which code sheet the
/// action opens, so that is all this carries. Building two screens instead
/// would have meant every later change to either one being a change to
/// both, with nothing enforcing that it was.
class InvitationsScreenConfig {
  const InvitationsScreenConfig({
    required this.codeActionLabel,
    required this.openCodeSheet,
    required this.emptyReceived,
    required this.emptySent,
  });

  /// The Club invites by player code; the Player joins by club code.
  final String Function(AppLocalizations) codeActionLabel;
  final Future<void> Function(BuildContext) openCodeSheet;

  final String Function(AppLocalizations) emptyReceived;
  final String Function(AppLocalizations) emptySent;

  static final club = InvitationsScreenConfig(
    codeActionLabel: (l10n) => l10n.inviteByCodeTitle,
    openCodeSheet: showInviteByCodeSheet,
    emptyReceived: (l10n) => l10n.invitationsEmptyReceived,
    emptySent: (l10n) => l10n.invitationsEmptySent,
  );

  static final player = InvitationsScreenConfig(
    codeActionLabel: (l10n) => l10n.joinByCodeTitle,
    openCodeSheet: showJoinByCodeSheet,
    emptyReceived: (l10n) => l10n.playerInvitationsEmptyReceived,
    emptySent: (l10n) => l10n.playerInvitationsEmptySent,
  );
}
