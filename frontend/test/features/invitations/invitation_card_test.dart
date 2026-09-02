// What the card shows and what it lets you press.
//
// The rendering rule worth pinning is that the card shows the *counterpart*
// and that its buttons come from the server's flags, not from the status.
// Getting the second one wrong is the failure that matters: a button the
// server will refuse looks exactly like a working one until it is tapped.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/invitations/application/invitations_controller.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitation.dart';
import 'package:sport_x_hub/features/invitations/presentation/shared/invitation_card.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

import '../../support/app_fonts.dart';

const _club = InvitationClub(
  id: 'club1',
  publicCode: 'CLB-000001',
  name: 'Al Ahly',
  city: 'Cairo',
  country: 'Egypt',
);

const _player = InvitationPlayer(
  id: 'player1',
  publicCode: 'PLY-000002',
  firstName: 'Omar',
  lastName: 'Hassan',
  sport: 'Football',
  position: 'CM',
);

Invitation _invitation({
  required InvitationType type,
  InvitationStatus status = InvitationStatus.pending,
  InvitationDirection direction = InvitationDirection.received,
  bool canAccept = false,
  bool canReject = false,
  bool canCancel = false,
  String? message,
}) => Invitation(
  id: 'inv1',
  type: type,
  status: status,
  direction: direction,
  canAccept: canAccept,
  canReject: canReject,
  canCancel: canCancel,
  message: message,
  club: _club,
  player: _player,
  expiresAt: DateTime.utc(2026, 3, 1),
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  Invitation invitation, {
  InvitationsListKind kind = InvitationsListKind.received,
}) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.compact(AppTheme.dark),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: InvitationCard(invitation: invitation, kind: kind),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  setUpAll(loadAppFonts);

  group('InvitationCard', () {
    testWidgets('a club-to-player invitation shows the player', (tester) async {
      await _pump(
        tester,
        _invitation(
          type: InvitationType.clubToPlayer,
          direction: InvitationDirection.sent,
          canCancel: true,
        ),
        kind: InvitationsListKind.sent,
      );

      // The club's own outbox is a list of players, not a list of itself.
      expect(find.text('Omar Hassan'), findsOneWidget);
      expect(find.text('PLY-000002'), findsOneWidget);
      expect(find.text('Al Ahly'), findsNothing);
    });

    testWidgets('a player-to-club request shows the player to the club', (
      tester,
    ) async {
      await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          direction: InvitationDirection.received,
          canAccept: true,
          canReject: true,
        ),
      );

      // The club is reading a request addressed to it: the useful half of
      // the card is who is asking, not the club's own name.
      expect(find.text('Omar Hassan'), findsOneWidget);
      expect(find.text('PLY-000002'), findsOneWidget);
      expect(find.text('Al Ahly'), findsNothing);
    });

    // The two cases the card used to get wrong. It chose a side from the
    // invitation's type alone, so whoever received one was shown their own
    // name and photograph instead of the person who had written to them.
    testWidgets('a club-to-player invitation shows the club to the player', (
      tester,
    ) async {
      await _pump(
        tester,
        _invitation(
          type: InvitationType.clubToPlayer,
          direction: InvitationDirection.received,
          canAccept: true,
          canReject: true,
        ),
      );

      expect(find.text('Al Ahly'), findsOneWidget);
      expect(find.text('CLB-000001'), findsOneWidget);
      expect(find.text('Omar Hassan'), findsNothing);
    });

    testWidgets('a player-to-club request shows the club in the outbox', (
      tester,
    ) async {
      await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          direction: InvitationDirection.sent,
          canCancel: true,
        ),
        kind: InvitationsListKind.sent,
      );

      expect(find.text('Al Ahly'), findsOneWidget);
      expect(find.text('Omar Hassan'), findsNothing);
    });

    testWidgets('the status is spelled out, not just coloured', (tester) async {
      final l10n = await _pump(
        tester,
        _invitation(type: InvitationType.playerToClub, status: InvitationStatus.expired),
      );

      expect(find.text(l10n.invitationStatusExpired), findsOneWidget);
    });

    testWidgets('only the actions the server granted are offered', (tester) async {
      final l10n = await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          canAccept: true,
          canReject: true,
        ),
      );

      expect(find.text(l10n.invitationAcceptLabel), findsOneWidget);
      expect(find.text(l10n.invitationRejectLabel), findsOneWidget);
      expect(find.text(l10n.invitationCancelInvitationLabel), findsNothing);
    });

    testWidgets('a sender is offered withdraw and nothing else', (tester) async {
      final l10n = await _pump(
        tester,
        _invitation(
          type: InvitationType.clubToPlayer,
          direction: InvitationDirection.sent,
          canCancel: true,
        ),
        kind: InvitationsListKind.sent,
      );

      expect(find.text(l10n.invitationCancelInvitationLabel), findsOneWidget);
      expect(find.text(l10n.invitationAcceptLabel), findsNothing);
      expect(find.text(l10n.invitationRejectLabel), findsNothing);
    });

    testWidgets('a settled invitation offers no actions at all', (tester) async {
      final l10n = await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          status: InvitationStatus.accepted,
        ),
      );

      expect(find.text(l10n.invitationAcceptLabel), findsNothing);
      expect(find.text(l10n.invitationRejectLabel), findsNothing);
      expect(find.text(l10n.invitationCancelInvitationLabel), findsNothing);
    });

    testWidgets('the expiry date shows while pending and not after', (tester) async {
      final l10n = await _pump(
        tester,
        _invitation(type: InvitationType.playerToClub, canAccept: true),
      );
      expect(find.text(l10n.invitationExpiresOn('2026-03-01')), findsOneWidget);

      await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          status: InvitationStatus.rejected,
        ),
      );
      // On a settled invitation the date is noise — nothing can lapse.
      expect(find.text(l10n.invitationExpiresOn('2026-03-01')), findsNothing);
    });

    testWidgets('the sender note is shown when there is one', (tester) async {
      await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          message: 'I train nearby and would love to join.',
          canAccept: true,
        ),
      );

      expect(find.text('I train nearby and would love to join.'), findsOneWidget);
    });

    testWidgets('rejecting asks first, and does nothing if dismissed', (tester) async {
      final l10n = await _pump(
        tester,
        _invitation(
          type: InvitationType.playerToClub,
          canAccept: true,
          canReject: true,
        ),
      );

      await tester.tap(find.text(l10n.invitationRejectLabel));
      await tester.pumpAndSettle();

      // Reject is terminal and reachable by mis-tap in a list, so it
      // confirms. Backing out must leave the invitation alone — with no
      // repository override in this scope, a request would throw.
      expect(find.text(l10n.invitationRejectConfirmTitle), findsOneWidget);
      await tester.tap(find.text(l10n.cancelLabel));
      await tester.pumpAndSettle();
      expect(find.text(l10n.invitationRejectConfirmTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepting does not ask — it is the outcome being sought', (
      tester,
    ) async {
      final l10n = await _pump(
        tester,
        _invitation(type: InvitationType.playerToClub, canAccept: true),
      );

      expect(find.text(l10n.invitationAcceptLabel), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
