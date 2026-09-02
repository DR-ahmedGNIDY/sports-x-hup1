// The Player's half of the feature: who sees the "request to join" action,
// what the Current Club card shows once a membership exists, and that the
// two roles' inbox screens really are one screen configured twice.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/auth/application/session_controller.dart';
import 'package:sport_x_hub/features/auth/application/session_state.dart';
import 'package:sport_x_hub/features/auth/domain/entities/app_user.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/features/club/domain/entities/club_profile.dart';
import 'package:sport_x_hub/features/invitations/data/repositories/memberships_repository_impl.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitation.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/membership.dart';
import 'package:sport_x_hub/features/invitations/domain/repositories/memberships_repository.dart';
import 'package:sport_x_hub/features/invitations/presentation/shared/invitations_screen_config.dart';
import 'package:sport_x_hub/features/invitations/presentation/shared/request_to_join_button.dart';
import 'package:sport_x_hub/features/player/domain/entities/player_profile.dart';
import 'package:sport_x_hub/features/player/presentation/shared/player_club_card.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

import '../../support/app_fonts.dart';

const _club = ClubProfile(id: 'club1', name: 'Al Ahly', city: 'Cairo');

class _FakeMemberships implements MembershipsRepository {
  _FakeMemberships({this.membership});

  final PlayerClubMembership? membership;

  @override
  Future<PlayerClubMembership?> findPlayerClub(String playerId) async => membership;

  @override
  Future<ClubMembersPage> listClubMembers(String clubId, {int page = 1}) async =>
      ClubMembersPage.empty;
}

/// A session pinned to [role] without going near storage or the network.
class _StubSession extends SessionController {
  _StubSession(this._role);

  final UserRole? _role;

  @override
  SessionState build() {
    if (_role == null) {
      return const SessionState(status: SessionStatus.unauthenticated);
    }
    return SessionState(
      status: SessionStatus.authenticated,
      user: AppUser(
        id: 'u1',
        role: _role,
        email: 'someone@example.test',
        status: 'ACTIVE',
      ),
    );
  }
}

Future<AppLocalizations> _pump(
  WidgetTester tester,
  Widget child, {
  UserRole? role,
  PlayerClubMembership? membership,
}) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _StubSession(role)),
        membershipsRepositoryProvider.overrideWithValue(
          _FakeMemberships(membership: membership),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(child: child);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  setUpAll(loadAppFonts);

  group('RequestToJoinButton', () {
    testWidgets('a Player sees it', (tester) async {
      final l10n = await _pump(
        tester,
        const RequestToJoinButton(club: _club),
        role: UserRole.player,
      );

      expect(find.text(l10n.requestToJoinLabel), findsOneWidget);
    });

    testWidgets('a Club does not — it cannot join itself', (tester) async {
      final l10n = await _pump(
        tester,
        const RequestToJoinButton(club: _club),
        role: UserRole.club,
      );

      expect(find.text(l10n.requestToJoinLabel), findsNothing);
    });

    testWidgets('a signed-out visitor does not', (tester) async {
      final l10n = await _pump(tester, const RequestToJoinButton(club: _club));

      expect(find.text(l10n.requestToJoinLabel), findsNothing);
    });
  });

  group('Current Club card', () {
    const player = PlayerProfile(
      id: 'p1',
      firstName: 'Omar',
      currentClub: 'Typed FC',
    );

    testWidgets('a real membership wins over the typed club name', (tester) async {
      await _pump(
        tester,
        const CurrentClubCard(profile: player),
        role: UserRole.player,
        membership: PlayerClubMembership(
          id: 'm1',
          club: const InvitationClub(id: 'club1', name: 'Al Ahly', city: 'Cairo'),
          joinedAt: DateTime.utc(2026, 1, 15),
        ),
      );

      // The membership is a fact both sides agreed to; the typed name is
      // not, and showing both would imply they had been reconciled.
      expect(find.text('Al Ahly'), findsOneWidget);
      expect(find.text('Typed FC'), findsNothing);
    });

    testWidgets('the join date is shown alongside the club', (tester) async {
      final l10n = await _pump(
        tester,
        const CurrentClubCard(profile: player),
        role: UserRole.player,
        membership: PlayerClubMembership(
          id: 'm1',
          club: const InvitationClub(id: 'club1', name: 'Al Ahly'),
          joinedAt: DateTime.utc(2026, 1, 15),
        ),
      );

      expect(find.text(l10n.membershipJoinedOn('2026-01-15')), findsOneWidget);
    });

    testWidgets('falls back to the typed club when there is no membership', (
      tester,
    ) async {
      await _pump(
        tester,
        const CurrentClubCard(profile: player),
        role: UserRole.player,
      );

      expect(find.text('Typed FC'), findsOneWidget);
    });

    testWidgets('shows the No Club state when there is neither', (tester) async {
      final l10n = await _pump(
        tester,
        const CurrentClubCard(profile: PlayerProfile(id: 'p1')),
        role: UserRole.player,
      );

      expect(find.text(l10n.noClubTitle), findsOneWidget);
    });
  });

  group('InvitationsScreenConfig', () {
    testWidgets('the two roles differ only in wording and which sheet opens', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final club = InvitationsScreenConfig.club;
      final player = InvitationsScreenConfig.player;

      expect(club.codeActionLabel(l10n), l10n.inviteByCodeTitle);
      expect(player.codeActionLabel(l10n), l10n.joinByCodeTitle);
      expect(club.emptySent(l10n), isNot(player.emptySent(l10n)));
      // Different sheets, not the same one relabelled — a Player opening
      // the player-code sheet would be looking up the wrong kind of code.
      expect(club.openCodeSheet, isNot(same(player.openCodeSheet)));
    });
  });
}
