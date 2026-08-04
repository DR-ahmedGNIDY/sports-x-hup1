import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../../player/data/models/player_search_result_model.dart';
import '../../../player/domain/entities/player_search_result.dart';
import '../../domain/repositories/saved_players_repository.dart';
import '../datasources/saved_players_remote_data_source.dart';

class SavedPlayersRepositoryImpl implements SavedPlayersRepository {
  SavedPlayersRepositoryImpl(this._remote, this._storage, this._ref);

  final SavedPlayersRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<List<PlayerSearchResult>> getSavedPlayers() => _authorized((token) async {
    final json = await _remote.getSavedPlayers(token);
    return json
        .map((e) => PlayerSearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<void> savePlayer(String playerId) =>
      _authorized((token) => _remote.savePlayer(token, playerId));

  @override
  Future<void> unsavePlayer(String playerId) =>
      _authorized((token) => _remote.unsavePlayer(token, playerId));
}

final savedPlayersRepositoryProvider = Provider<SavedPlayersRepository>(
  (ref) => SavedPlayersRepositoryImpl(
    ref.watch(savedPlayersRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
