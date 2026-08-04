import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/admin_club_summary.dart';
import '../../domain/entities/admin_player_summary.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';
import '../models/admin_club_summary_model.dart';
import '../models/admin_player_summary_model.dart';
import '../models/admin_user_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote, this._storage, this._ref);

  final AdminRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<List<AdminUser>> getUsers() => _authorized((token) async {
    final json = await _remote.getUsers(token);
    return json.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
  });

  @override
  Future<void> setUserStatus(String userId, String status) =>
      _authorized((token) => _remote.setUserStatus(token, userId, status));

  @override
  Future<void> deleteUser(String userId) =>
      _authorized((token) => _remote.deleteUser(token, userId));

  @override
  Future<List<AdminPlayerSummary>> getPlayers() => _authorized((token) async {
    final json = await _remote.getPlayers(token);
    return json
        .map((e) => AdminPlayerSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<void> deletePlayer(String playerId) =>
      _authorized((token) => _remote.deletePlayer(token, playerId));

  @override
  Future<List<AdminClubSummary>> getClubs() => _authorized((token) async {
    final json = await _remote.getClubs(token);
    return json
        .map((e) => AdminClubSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<void> deleteClub(String clubId) =>
      _authorized((token) => _remote.deleteClub(token, clubId));
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(
    ref.watch(adminRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
