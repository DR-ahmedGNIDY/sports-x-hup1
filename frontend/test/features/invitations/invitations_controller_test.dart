// The list controller's two jobs that a screen would otherwise get wrong:
// keeping the page and status filter across a state transition, and writing
// the server's answer back into the row rather than guessing at it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/invitations/application/invitations_controller.dart';
import 'package:sport_x_hub/features/invitations/data/repositories/invitations_repository_impl.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitation.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitations_page.dart';
import 'package:sport_x_hub/features/invitations/domain/entities/invitations_summary.dart';
import 'package:sport_x_hub/features/invitations/domain/repositories/invitations_repository.dart';

Invitation _invitation(
  String id, {
  InvitationStatus status = InvitationStatus.pending,
  bool canAccept = true,
}) => Invitation(
  id: id,
  type: InvitationType.playerToClub,
  status: status,
  direction: InvitationDirection.received,
  canAccept: canAccept,
  canReject: canAccept,
  canCancel: false,
);

/// Records what it was asked for, and answers with whatever the test set.
class _FakeRepository implements InvitationsRepository {
  _FakeRepository({this.page = InvitationsPage.empty});

  InvitationsPage page;
  final List<({String list, int page, InvitationStatus? status})> reads = [];
  Invitation? acceptAnswer;

  @override
  Future<InvitationsPage> listReceived({int page = 1, InvitationStatus? status}) async {
    reads.add((list: 'received', page: page, status: status));
    return this.page;
  }

  @override
  Future<InvitationsPage> listSent({int page = 1, InvitationStatus? status}) async {
    reads.add((list: 'sent', page: page, status: status));
    return this.page;
  }

  @override
  Future<Invitation> accept(String id) async =>
      acceptAnswer ?? _invitation(id, status: InvitationStatus.accepted, canAccept: false);

  @override
  Future<Invitation> reject(String id) async =>
      _invitation(id, status: InvitationStatus.rejected, canAccept: false);

  @override
  Future<Invitation> cancel(String id) async =>
      _invitation(id, status: InvitationStatus.cancelled, canAccept: false);

  @override
  Future<InvitationsSummary> getSummary() async => InvitationsSummary.empty;

  @override
  Future<Invitation> invitePlayer({
    String? playerId,
    String? playerCode,
    String? message,
  }) async => _invitation('new');

  @override
  Future<Invitation> requestToJoinClub({
    String? clubId,
    String? clubCode,
    String? message,
  }) async => _invitation('new');
}

ProviderContainer _containerWith(_FakeRepository repository) {
  final container = ProviderContainer(
    overrides: [invitationsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('InvitationsListController', () {
    test('each inbox reads its own endpoint', () async {
      final repository = _FakeRepository();
      final container = _containerWith(repository);

      await container.read(invitationsListProvider(InvitationsListKind.received).future);
      await container.read(invitationsListProvider(InvitationsListKind.sent).future);

      expect(repository.reads.map((r) => r.list), ['received', 'sent']);
    });

    test('a status filter is sent to the server and resets to page one', () async {
      final repository = _FakeRepository();
      final container = _containerWith(repository);
      const kind = InvitationsListKind.received;

      await container.read(invitationsListProvider(kind).future);
      final controller = container.read(invitationsListProvider(kind).notifier);
      await controller.loadPage(3);
      await controller.applyStatus(InvitationStatus.pending);

      // Filtering a paginated list from page 3 would otherwise show
      // "matching rows on page 3", which is not what the chip claims.
      expect(repository.reads.last.page, 1);
      expect(repository.reads.last.status, InvitationStatus.pending);
      expect(controller.statusFilter, InvitationStatus.pending);
    });

    test('paging keeps the active status filter', () async {
      final repository = _FakeRepository();
      final container = _containerWith(repository);
      const kind = InvitationsListKind.sent;

      await container.read(invitationsListProvider(kind).future);
      final controller = container.read(invitationsListProvider(kind).notifier);
      await controller.applyStatus(InvitationStatus.accepted);
      await controller.loadPage(2);

      expect(repository.reads.last.page, 2);
      expect(repository.reads.last.status, InvitationStatus.accepted);
    });

    test('accepting rewrites the row in place, keeping page and filter', () async {
      final repository = _FakeRepository(
        page: InvitationsPage(
          items: [_invitation('a'), _invitation('b')],
          page: 2,
          pageSize: 20,
          total: 40,
        ),
      );
      final container = _containerWith(repository);
      const kind = InvitationsListKind.received;

      await container.read(invitationsListProvider(kind).future);
      final controller = container.read(invitationsListProvider(kind).notifier);
      await controller.loadPage(2);
      final readsBefore =
          repository.reads.where((r) => r.list == 'received').length;

      await controller.accept('a');

      final state = container.read(invitationsListProvider(kind)).value!;
      final accepted = state.items.firstWhere((i) => i.id == 'a');
      expect(accepted.status, InvitationStatus.accepted);
      expect(accepted.canAccept, isFalse);
      // The row stays put — an accepted invitation must not vanish from
      // under the finger that tapped it.
      expect(state.items.map((i) => i.id), ['a', 'b']);
      expect(state.page, 2);
      // And *this* list is not refetched: doing so would reset the notifier
      // and silently drop the page the viewer is on. (The opposite inbox is
      // refetched on purpose — see the next test.)
      expect(
        repository.reads.where((r) => r.list == 'received').length,
        readsBefore,
      );
    });

    test('rejecting and cancelling rewrite the row the same way', () async {
      final repository = _FakeRepository(
        page: InvitationsPage(
          items: [_invitation('a'), _invitation('b')],
          page: 1,
          pageSize: 20,
          total: 2,
        ),
      );
      final container = _containerWith(repository);
      const kind = InvitationsListKind.received;

      await container.read(invitationsListProvider(kind).future);
      final controller = container.read(invitationsListProvider(kind).notifier);
      await controller.reject('a');
      await controller.cancel('b');

      final items = container.read(invitationsListProvider(kind)).value!.items;
      expect(items.first.status, InvitationStatus.rejected);
      expect(items.last.status, InvitationStatus.cancelled);
    });

    test('a transition invalidates the opposite inbox', () async {
      final repository = _FakeRepository(
        page: InvitationsPage(
          items: [_invitation('a')],
          page: 1,
          pageSize: 20,
          total: 1,
        ),
      );
      final container = _containerWith(repository);

      await container.read(invitationsListProvider(InvitationsListKind.received).future);
      await container.read(invitationsListProvider(InvitationsListKind.sent).future);
      final sentReadsBefore =
          repository.reads.where((r) => r.list == 'sent').length;

      await container
          .read(invitationsListProvider(InvitationsListKind.received).notifier)
          .accept('a');
      await container.read(invitationsListProvider(InvitationsListKind.sent).future);

      // Accepting a join request cancels the club's own pending invitations
      // to that player, so the Sent tab can no longer be trusted.
      expect(
        repository.reads.where((r) => r.list == 'sent').length,
        greaterThan(sentReadsBefore),
      );
    });
  });

  group('InvitationsListKind', () {
    test('each inbox knows its opposite', () {
      expect(InvitationsListKind.received.other, InvitationsListKind.sent);
      expect(InvitationsListKind.sent.other, InvitationsListKind.received);
    });
  });
}
