import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/club_profile.dart';
import '../../domain/repositories/club_repository.dart';
import '../datasources/club_remote_data_source.dart';
import '../models/club_profile_model.dart';

class ClubRepositoryImpl implements ClubRepository {
  ClubRepositoryImpl(this._remote, this._storage, this._ref);

  final ClubRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<ClubProfile> getMyProfile() => _authorized((token) async {
    final json = await _remote.getMyProfile(token);
    return ClubProfileModel.fromJson(json);
  });

  @override
  Future<ClubProfile> updateMyProfile({
    String? name,
    String? country,
    String? city,
    String? description,
    int? foundedYear,
    String? level,
  }) => _authorized((token) async {
    final json = await _remote.updateMyProfile(token, {
      'name': ?name,
      'country': ?country,
      'city': ?city,
      'description': ?description,
      'foundedYear': ?foundedYear,
      'level': ?level,
    });
    return ClubProfileModel.fromJson(json);
  });

  @override
  Future<ClubProfile> uploadLogo({
    required List<int> bytes,
    required String filename,
  }) => _authorized((token) async {
    final json = await _remote.uploadLogo(token, bytes: bytes, filename: filename);
    return ClubProfileModel.fromJson(json);
  });
}

final clubRepositoryProvider = Provider<ClubRepository>(
  (ref) => ClubRepositoryImpl(
    ref.watch(clubRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
