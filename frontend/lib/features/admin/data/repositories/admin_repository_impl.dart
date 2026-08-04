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
  Future<AdminPage<AdminUser>> getUsers({int page = 1}) => _authorized((token) async {
    final json = await _remote.getUsers(token, page: page);
    return _toPage(json, AdminUserModel.fromJson);
  });

  @override
  Future<void> setUserStatus(String userId, String status) =>
      _authorized((token) => _remote.setUserStatus(token, userId, status));

  @override
  Future<void> deleteUser(String userId) =>
      _authorized((token) => _remote.deleteUser(token, userId));

  @override
  Future<AdminPage<AdminPlayerSummary>> getPlayers({int page = 1}) =>
      _authorized((token) async {
        final json = await _remote.getPlayers(token, page: page);
        return _toPage(json, AdminPlayerSummaryModel.fromJson);
      });

  @override
  Future<void> deletePlayer(String playerId) =>
      _authorized((token) => _remote.deletePlayer(token, playerId));

  @override
  Future<AdminPage<AdminClubSummary>> getClubs({int page = 1}) =>
      _authorized((token) async {
        final json = await _remote.getClubs(token, page: page);
        return _toPage(json, AdminClubSummaryModel.fromJson);
      });

  @override
  Future<void> deleteClub(String clubId) =>
      _authorized((token) => _remote.deleteClub(token, clubId));

  /// Decodes the `{items, page, pageSize, total}` envelope every admin list
  /// endpoint returns into an [AdminPage].
  AdminPage<T> _toPage<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (json['items'] as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    final page = json['page'] as int;
    final pageSize = json['pageSize'] as int;
    final total = json['total'] as int;
    return (items: items, hasMore: page * pageSize < total);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(
    ref.watch(adminRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
