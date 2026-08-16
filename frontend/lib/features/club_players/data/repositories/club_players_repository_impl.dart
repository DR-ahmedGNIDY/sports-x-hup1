import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../../player/domain/entities/contact_details.dart';
import '../../../player/domain/entities/player_enums.dart';
import '../../domain/entities/club_dashboard_summary.dart';
import '../../domain/entities/club_managed_player.dart';
import '../../domain/entities/club_player_credentials.dart';
import '../../domain/entities/club_players_filters.dart';
import '../../domain/entities/club_roster_page.dart';
import '../../domain/entities/create_club_player_input.dart';
import '../../domain/repositories/club_players_repository.dart';
import '../datasources/club_players_remote_data_source.dart';
import '../models/club_managed_player_model.dart';

class ClubPlayersRepositoryImpl implements ClubPlayersRepository {
  ClubPlayersRepositoryImpl(this._remote, this._storage, this._ref);

  final ClubPlayersRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<ClubRosterPage> listPlayers(ClubPlayersFilters filters) =>
      _authorized((token) async {
        final json = await _remote.list(
          token,
          page: filters.page,
          search: filters.search,
          sport: filters.sport,
          position: filters.position,
        );
        return ClubRosterPageModel.fromJson(json);
      });

  @override
  Future<ClubDashboardSummary> getSummary() => _authorized((token) async {
    final json = await _remote.summary(token);
    return ClubDashboardSummaryModel.fromJson(json);
  });

  @override
  Future<({ClubManagedPlayer player, ClubPlayerCredentials credentials})>
  createPlayer(CreateClubPlayerInput input) => _authorized((token) async {
    final body = createClubPlayerInputToJson(
      firstName: input.firstName,
      lastName: input.lastName,
      phone: input.phone,
      countryIsoCode: input.countryIsoCode,
      email: input.email,
      dateOfBirth: input.dateOfBirth,
      nationality: input.nationality,
      country: input.country,
      city: input.city,
      sport: input.sport,
      position: input.position,
      preferredFoot: input.preferredFoot?.wireValue,
      height: input.height,
      weight: input.weight,
      currentStatus: input.currentStatus,
      currentClub: input.currentClub,
      bio: input.bio,
    );
    final json = await _remote.create(token, body);
    return (
      player: ClubManagedPlayerModel.fromJson(json['player'] as Map<String, dynamic>),
      credentials: ClubPlayerCredentialsModel.fromJson(
        json['credentials'] as Map<String, dynamic>,
      ),
    );
  });

  @override
  Future<ClubManagedPlayer> getPlayer(String userId) => _authorized((token) async {
    final json = await _remote.getOne(token, userId);
    return ClubManagedPlayerModel.fromJson(json);
  });

  @override
  Future<ClubManagedPlayer> uploadPhoto(
    String userId, {
    required List<int> bytes,
    required String filename,
  }) => _authorized((token) async {
    final json = await _remote.uploadPhoto(
      token,
      userId,
      bytes: bytes,
      filename: filename,
    );
    return ClubManagedPlayerModel.fromJson(json);
  });

  @override
  Future<ClubManagedPlayer> updatePlayer(
    String userId, {
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? country,
    String? city,
    String? sport,
    String? position,
    PreferredFoot? preferredFoot,
    num? height,
    num? weight,
    String? currentStatus,
    String? currentClub,
    String? bio,
    ContactDetails? contact,
  }) => _authorized((token) async {
    final body = updateClubPlayerInputToJson(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      country: country,
      city: city,
      sport: sport,
      position: position,
      preferredFoot: preferredFoot?.wireValue,
      height: height,
      weight: weight,
      currentStatus: currentStatus,
      currentClub: currentClub,
      bio: bio,
      contact: contact,
    );
    final json = await _remote.update(token, userId, body);
    return ClubManagedPlayerModel.fromJson(json);
  });

  @override
  Future<void> removePlayer(String userId) =>
      _authorized((token) => _remote.remove(token, userId));

  @override
  Future<ClubPlayerCredentials> resendCredentials(String userId) =>
      _authorized((token) async {
        final json = await _remote.resendCredentials(token, userId);
        return ClubPlayerCredentialsModel.fromJson(
          json['credentials'] as Map<String, dynamic>,
        );
      });
}

final clubPlayersRepositoryProvider = Provider<ClubPlayersRepository>(
  (ref) => ClubPlayersRepositoryImpl(
    ref.watch(clubPlayersRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
