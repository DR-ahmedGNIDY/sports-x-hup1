import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/memberships_repository_impl.dart';
import '../domain/entities/membership.dart';

/// The club a player belongs to, for their public profile. autoDispose for
/// the same reason `publicPlayerProfileProvider` is: a profile someone
/// browsed once is not reference data.
final playerClubProvider =
    FutureProvider.autoDispose.family<PlayerClubMembership?, String>(
      (ref, playerId) =>
          ref.watch(membershipsRepositoryProvider).findPlayerClub(playerId),
    );

/// One page of a club's roster. Keyed by club *and* page so paging is a
/// new provider rather than mutable state — the roster is read-only, so
/// there is nothing here for a notifier to own.
final clubMembersProvider = FutureProvider.autoDispose
    .family<ClubMembersPage, ({String clubId, int page})>(
      (ref, key) => ref
          .watch(membershipsRepositoryProvider)
          .listClubMembers(key.clubId, page: key.page),
    );
