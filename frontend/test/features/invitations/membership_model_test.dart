// The membership wire shape, pinned against `memberships.mapper.ts`.
//
// The case worth guarding is the empty one: "this player has no club" is an
// ordinary answer the backend returns as 200 with a null membership, and a
// decoder that treated it as malformed would break every profile page
// belonging to a player who has not joined anywhere.
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/invitations/data/models/membership_model.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/membership.dart';

Map<String, dynamic> _membershipEnvelope() => {
  'membership': <String, dynamic>{
    'id': 'membership-1',
    'joinedAt': '2026-01-15T00:00:00.000Z',
    'club': <String, dynamic>{
      'id': 'club1',
      'publicCode': 'CLB-000001',
      'name': 'Al Ahly',
      'city': 'Cairo',
      'country': 'Egypt',
      'level': 'PROFESSIONAL',
      'logoUrl': 'https://example.test/logo.png',
    },
  },
};

Map<String, dynamic> _memberRow() => {
  'id': 'player1',
  'publicCode': 'PLY-000002',
  'firstName': 'Omar',
  'lastName': 'Hassan',
  'sport': 'Football',
  'position': 'CM',
  'country': 'Egypt',
  'profilePhotoUrl': 'https://example.test/photo.png',
  'joinedAt': '2026-02-01T00:00:00.000Z',
};

void main() {
  group('PlayerClubMembershipModel', () {
    test('decodes the club a player belongs to', () {
      final membership =
          PlayerClubMembershipModel.fromEnvelope(_membershipEnvelope())!;

      expect(membership.id, 'membership-1');
      expect(membership.club.name, 'Al Ahly');
      expect(membership.club.publicCode, 'CLB-000001');
      expect(membership.club.location, 'Cairo, Egypt');
      expect(membership.joinedAt, DateTime.utc(2026, 1, 15));
    });

    test('a player with no club decodes to null, not an error', () {
      expect(
        PlayerClubMembershipModel.fromEnvelope({'membership': null}),
        isNull,
      );
    });

    test('a membership whose club is gone reads as no club', () {
      final envelope = _membershipEnvelope();
      (envelope['membership'] as Map<String, dynamic>)['club'] = null;

      // Half a card is worse than none: there is nothing to name or link to.
      expect(PlayerClubMembershipModel.fromEnvelope(envelope), isNull);
    });
  });

  group('ClubMembersPageModel', () {
    test('decodes a roster page and each member’s join date', () {
      final page = ClubMembersPageModel.fromJson({
        'items': [_memberRow()],
        'page': 1,
        'pageSize': 20,
        'total': 1,
      });

      expect(page.items, hasLength(1));
      expect(page.items.single.player.fullName, 'Omar Hassan');
      expect(page.items.single.player.publicCode, 'PLY-000002');
      expect(page.items.single.joinedAt, DateTime.utc(2026, 2, 1));
      expect(page.hasNextPage, isFalse);
    });

    test('pages when the visible total exceeds one page', () {
      final page = ClubMembersPageModel.fromJson({
        'items': [_memberRow()],
        'page': 1,
        'pageSize': 20,
        'total': 25,
      });

      expect(page.hasNextPage, isTrue);
    });

    test('an empty roster decodes without inventing rows', () {
      final page = ClubMembersPageModel.fromJson({
        'items': <dynamic>[],
        'page': 1,
        'pageSize': 20,
        'total': 0,
      });

      expect(page.items, isEmpty);
      expect(ClubMembersPage.empty.items, isEmpty);
    });
  });
}
