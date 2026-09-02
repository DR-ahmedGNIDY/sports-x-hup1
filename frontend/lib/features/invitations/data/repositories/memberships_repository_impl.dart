import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/membership.dart';
import '../../domain/repositories/memberships_repository.dart';
import '../datasources/memberships_remote_data_source.dart';
import '../models/membership_model.dart';

class MembershipsRepositoryImpl implements MembershipsRepository {
  MembershipsRepositoryImpl(this._remote);

  final MembershipsRemoteDataSource _remote;

  @override
  Future<PlayerClubMembership?> findPlayerClub(String playerId) async {
    return PlayerClubMembershipModel.fromEnvelope(
      await _remote.getPlayerClub(playerId),
    );
  }

  @override
  Future<ClubMembersPage> listClubMembers(String clubId, {int page = 1}) async {
    return ClubMembersPageModel.fromJson(
      await _remote.listClubMembers(clubId, page: page),
    );
  }
}

final membershipsRepositoryProvider = Provider<MembershipsRepository>(
  (ref) => MembershipsRepositoryImpl(ref.watch(membershipsRemoteDataSourceProvider)),
);
