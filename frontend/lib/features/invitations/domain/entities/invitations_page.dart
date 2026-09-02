import 'invitation.dart';

/// One page of `GET /invitations/received` or `/sent` — the project's
/// standard page-based envelope, same shape and page size as every other
/// paginated list in the app.
class InvitationsPage {
  const InvitationsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<Invitation> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;

  static const empty = InvitationsPage(items: [], page: 1, pageSize: 20, total: 0);
}
