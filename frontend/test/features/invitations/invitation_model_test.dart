// Decoding is the one place this feature can fail silently: every rule the
// backend enforces arrives here as a field, and a field that parses wrong
// produces a card that lies about what the viewer can do. These pin the
// wire shape against `toInvitationView` in
// `backend/src/invitations/invitations.mapper.ts`.
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/invitations/data/models/invitation_model.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitation.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitations_page.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitations_summary.dart';

Map<String, dynamic> _fullPayload() => {
  'id': 'inv1',
  'type': 'CLUB_TO_PLAYER',
  'status': 'PENDING',
  'direction': 'SENT',
  'message': 'Come and train with us.',
  'club': {
    'id': 'club1',
    'publicCode': 'CLB-000001',
    'name': 'Al Ahly',
    'city': 'Cairo',
    'country': 'Egypt',
    'level': 'PROFESSIONAL',
    'logoUrl': 'https://example.test/logo.png',
  },
  'player': {
    'id': 'player1',
    'publicCode': 'PLY-000002',
    'firstName': 'Omar',
    'lastName': 'Hassan',
    'sport': 'Football',
    'position': 'CM',
    'country': 'Egypt',
    'profilePhotoUrl': 'https://example.test/photo.png',
  },
  'canAccept': false,
  'canReject': false,
  'canCancel': true,
  'createdAt': '2026-01-02T10:00:00.000Z',
  'updatedAt': '2026-01-02T10:00:00.000Z',
  'expiresAt': '2026-02-01T10:00:00.000Z',
  'respondedAt': null,
};

void main() {
  group('InvitationModel', () {
    test('decodes a full invitation, both sides included', () {
      final invitation = InvitationModel.fromJson(_fullPayload());

      expect(invitation.id, 'inv1');
      expect(invitation.type, InvitationType.clubToPlayer);
      expect(invitation.status, InvitationStatus.pending);
      expect(invitation.direction, InvitationDirection.sent);
      expect(invitation.message, 'Come and train with us.');
      expect(invitation.club?.publicCode, 'CLB-000001');
      expect(invitation.club?.location, 'Cairo, Egypt');
      expect(invitation.player?.fullName, 'Omar Hassan');
      expect(invitation.player?.publicCode, 'PLY-000002');
      expect(invitation.expiresAt, DateTime.utc(2026, 2, 1, 10));
      expect(invitation.respondedAt, isNull);
      expect(invitation.isPending, isTrue);
    });

    test('carries the permissions the server granted, not derived ones', () {
      final invitation = InvitationModel.fromJson(_fullPayload());

      // Pending and the viewer's own — but the server said "cancel only",
      // and that is what the card must offer.
      expect(invitation.canCancel, isTrue);
      expect(invitation.canAccept, isFalse);
      expect(invitation.canReject, isFalse);
    });

    test('a deleted counterpart decodes to null rather than throwing', () {
      final payload = _fullPayload()
        ..['club'] = null
        ..['player'] = null
        ..['message'] = null;

      final invitation = InvitationModel.fromJson(payload);

      expect(invitation.club, isNull);
      expect(invitation.player, isNull);
      expect(invitation.message, isNull);
    });

    test('missing permission flags default to no actions', () {
      final payload = _fullPayload()
        ..remove('canAccept')
        ..remove('canReject')
        ..remove('canCancel');

      final invitation = InvitationModel.fromJson(payload);

      // Defaulting to false is the safe direction: a missing flag must not
      // render a button the server would refuse.
      expect(invitation.canAccept, isFalse);
      expect(invitation.canReject, isFalse);
      expect(invitation.canCancel, isFalse);
    });

    test('an unparseable date is dropped, not fatal', () {
      final payload = _fullPayload()..['expiresAt'] = 'not-a-date';

      expect(InvitationModel.fromJson(payload).expiresAt, isNull);
    });

    test('every status the backend can send is decodable', () {
      for (final wire in [
        'PENDING',
        'ACCEPTED',
        'REJECTED',
        'CANCELLED',
        'EXPIRED',
      ]) {
        final payload = _fullPayload()..['status'] = wire;
        expect(InvitationModel.fromJson(payload).status.wireValue, wire);
      }
    });
  });

  group('InvitationsPageModel', () {
    test('decodes the standard page envelope', () {
      final page = InvitationsPageModel.fromJson({
        'items': [_fullPayload()],
        'page': 2,
        'pageSize': 20,
        'total': 25,
      });

      expect(page.items, hasLength(1));
      expect(page.page, 2);
      expect(page.hasNextPage, isFalse);
    });

    test('knows there is another page when the total exceeds what is loaded', () {
      final page = InvitationsPageModel.fromJson({
        'items': [_fullPayload()],
        'page': 1,
        'pageSize': 20,
        'total': 25,
      });

      expect(page.hasNextPage, isTrue);
    });

    test('an empty list decodes without inventing a page', () {
      final page = InvitationsPageModel.fromJson({
        'items': <dynamic>[],
        'page': 1,
        'pageSize': 20,
        'total': 0,
      });

      expect(page.items, isEmpty);
      expect(page.hasNextPage, isFalse);
    });
  });

  group('InvitationsSummaryModel', () {
    test('decodes both pending counts', () {
      final summary = InvitationsSummaryModel.fromJson({
        'pendingReceived': 3,
        'pendingSent': 1,
      });

      expect(summary.pendingReceived, 3);
      expect(summary.pendingSent, 1);
    });

    test('treats an absent count as zero', () {
      final summary = InvitationsSummaryModel.fromJson(<String, dynamic>{});

      expect(summary.pendingReceived, 0);
      expect(summary.pendingSent, 0);
      expect(InvitationsSummary.empty.pendingReceived, 0);
      expect(InvitationsPage.empty.items, isEmpty);
    });
  });
}
