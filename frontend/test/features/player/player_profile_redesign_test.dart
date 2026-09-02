// Widget tests for the Player Profile premium-redesign pieces: the Hero
// Card's owner-only action slot, Quick Stats' "hide missing facts" rule,
// the Current Club card's new always-render "No Club" state, and the
// Achievements section's "hide entirely when empty" rule.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/invitations/data/repositories/memberships_repository_impl.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/membership.dart';
import 'package:sport_x_hub/features/invitations/domain/repositories/memberships_repository.dart';
import 'package:sport_x_hub/features/player/domain/entities/achievement.dart';
import 'package:sport_x_hub/features/player/domain/entities/player_profile.dart';
import 'package:sport_x_hub/features/player/presentation/shared/player_club_card.dart';
import 'package:sport_x_hub/features/player/presentation/shared/player_hero_card.dart';
import 'package:sport_x_hub/features/player/presentation/shared/player_profile_data.dart';
import 'package:sport_x_hub/features/player/presentation/shared/player_profile_trailing_sections.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

/// A repository that reports "this player has no club". The Current Club
/// card reads a membership now, so without an override these tests would
/// try to reach a backend — and the point of the two below is what the card
/// falls back to when there is no membership, not what the network does.
class _NoMembershipRepository implements MembershipsRepository {
  @override
  Future<PlayerClubMembership?> findPlayerClub(String playerId) async => null;

  @override
  Future<ClubMembersPage> listClubMembers(String clubId, {int page = 1}) async =>
      ClubMembersPage.empty;
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      membershipsRepositoryProvider.overrideWithValue(_NoMembershipRepository()),
    ],
    child: MaterialApp(
      // Player Profile widgets read colors via `context.profileColors`
      // (see core/theme/profile_colors.dart), which requires the
      // `ProfileColors` ThemeExtension the real app always registers
      // through AppTheme — a bare/default ThemeData doesn't have it.
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

const _basePlayer = PlayerProfile(id: 'p1', firstName: 'Amina', lastName: 'Test');

void main() {
  group('PlayerHeroCard', () {
    testWidgets('shows the actions slot when provided (owner view)', (tester) async {
      await tester.pumpWidget(
        _wrap(const PlayerHeroCard(profile: _basePlayer, actions: Text('EDIT_ACTION'))),
      );
      expect(find.text('EDIT_ACTION'), findsOneWidget);
    });

    testWidgets('omits the actions slot when not provided (public view)', (tester) async {
      await tester.pumpWidget(_wrap(const PlayerHeroCard(profile: _basePlayer)));
      expect(find.text('EDIT_ACTION'), findsNothing);
    });

    testWidgets('renders the player name', (tester) async {
      await tester.pumpWidget(_wrap(const PlayerHeroCard(profile: _basePlayer)));
      expect(find.text('Amina Test'), findsOneWidget);
    });
  });

  group('buildQuickFacts', () {
    testWidgets('omits facts for null fields instead of fabricating values', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _wrap(Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        })),
      );
      final l10n = AppLocalizations.of(capturedContext)!;

      // Nothing set: no facts at all.
      expect(buildQuickFacts(l10n, _basePlayer), isEmpty);

      // Only height set: exactly one fact.
      final withHeight = PlayerProfile(id: 'p1', height: 180);
      final facts = buildQuickFacts(l10n, withHeight);
      expect(facts, hasLength(1));
      expect(facts.single.value, '180 cm');
    });
  });

  group('buildCurrentClubCard', () {
    testWidgets('shows a professional "No Club" state instead of hiding the card', (tester) async {
      await tester.pumpWidget(
        _wrap(Builder(builder: (context) => buildCurrentClubCard(context, _basePlayer))),
      );
      expect(find.text('No Club'), findsOneWidget);
    });

    testWidgets('shows the club name when currentClub is set', (tester) async {
      const withClub = PlayerProfile(id: 'p1', currentClub: 'FC Example');
      await tester.pumpWidget(
        _wrap(Builder(builder: (context) => buildCurrentClubCard(context, withClub))),
      );
      expect(find.text('FC Example'), findsOneWidget);
      expect(find.text('No Club'), findsNothing);
    });
  });

  group('buildAchievementsSection', () {
    testWidgets('is null (hidden) when there are no achievements', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _wrap(Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        })),
      );
      expect(buildAchievementsSection(capturedContext, _basePlayer), isNull);
    });

    testWidgets('renders a gold achievement card when achievements exist', (tester) async {
      final withAchievement = PlayerProfile(
        id: 'p1',
        achievements: const [Achievement(id: 'a1', title: 'League Winner', year: 2024)],
      );
      late Widget? section;
      await tester.pumpWidget(
        _wrap(Builder(builder: (context) {
          section = buildAchievementsSection(context, withAchievement);
          return section ?? const SizedBox.shrink();
        })),
      );
      expect(section, isNotNull);
      expect(find.text('League Winner'), findsOneWidget);
    });
  });
}
