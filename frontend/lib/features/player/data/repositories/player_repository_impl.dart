import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../domain/entities/contact_details.dart';
import '../../domain/entities/lookup_option.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_data_source.dart';
import '../models/lookup_option_model.dart';
import '../models/player_profile_model.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl(this._remote, this._storage, this._ref);

  final PlayerRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  /// Runs [call] with the current access token; on a 401 it forces one
  /// refresh attempt (via AuthRepository.restoreSession, which already
  /// owns the refresh-token flow) and retries once.
  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) async {
    final token = _storage.accessToken;
    if (token == null) throw const AppException('You are not signed in.');
    try {
      return await call(token);
    } on AppException catch (e) {
      if (e.statusCode != 401) rethrow;
      await _ref.read(authRepositoryProvider).restoreSession();
      final refreshed = _storage.accessToken;
      if (refreshed == null) rethrow;
      return call(refreshed);
    }
  }

  Map<String, dynamic>? _contactToJson(ContactDetails? contact) {
    if (contact == null) return null;
    return {
      'phone': ?contact.phone,
      'email': ?contact.email,
      'whatsapp': ?contact.whatsapp,
    };
  }

  @override
  Future<PlayerProfile> getMyProfile() =>
      _authorized((token) async {
        final json = await _remote.getMyProfile(token);
        return PlayerProfileModel.fromJson(json);
      });

  @override
  Future<PlayerProfile> updateMyProfile({
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
    final json = await _remote.updateMyProfile(token, {
      'firstName': ?firstName,
      'lastName': ?lastName,
      'dateOfBirth': ?dateOfBirth?.toIso8601String(),
      'nationality': ?nationality,
      'country': ?country,
      'city': ?city,
      'sport': ?sport,
      'position': ?position,
      'preferredFoot': ?preferredFoot?.wireValue,
      'height': ?height,
      'weight': ?weight,
      'currentStatus': ?currentStatus,
      'currentClub': ?currentClub,
      'bio': ?bio,
      'contact': ?_contactToJson(contact),
    });
    return PlayerProfileModel.fromJson(json);
  });

  @override
  Future<PlayerProfile> updateVisibility(ProfileVisibility visibility) =>
      _authorized((token) async {
        final json = await _remote.updateVisibility(token, visibility.wireValue);
        return PlayerProfileModel.fromJson(json);
      });

  @override
  Future<PlayerProfile> uploadMedia({
    required List<int> bytes,
    required String filename,
    required PlayerMediaType type,
    bool isProfilePhoto = false,
  }) => _authorized((token) async {
    final json = await _remote.uploadMedia(
      token,
      bytes: bytes,
      filename: filename,
      type: type.wireValue,
      isProfilePhoto: isProfilePhoto,
    );
    return PlayerProfileModel.fromJson(json);
  });

  @override
  Future<PlayerProfile> deleteMedia(String mediaId) =>
      _authorized((token) async {
        final json = await _remote.deleteMedia(token, mediaId);
        return PlayerProfileModel.fromJson(json);
      });

  @override
  Future<PlayerProfile> addAchievement({
    required String title,
    required int year,
    String? description,
  }) => _authorized((token) async {
    final json = await _remote.addAchievement(token, {
      'title': title,
      'year': year,
      'description': ?description,
    });
    return PlayerProfileModel.fromJson(json);
  });

  @override
  Future<PlayerProfile> updateAchievement(
    String id, {
    String? title,
    int? year,
    String? description,
  }) => _authorized((token) async {
    final json = await _remote.updateAchievement(token, id, {
      'title': ?title,
      'year': ?year,
      'description': ?description,
    });
    return PlayerProfileModel.fromJson(json);
  });

  @override
  Future<PlayerProfile> deleteAchievement(String id) =>
      _authorized((token) async {
        final json = await _remote.deleteAchievement(token, id);
        return PlayerProfileModel.fromJson(json);
      });

  @override
  Future<PlayerProfile> addSocialLink({required String platform, required String url}) =>
      _authorized((token) async {
        final json = await _remote.addSocialLink(token, {
          'platform': platform,
          'url': url,
        });
        return PlayerProfileModel.fromJson(json);
      });

  @override
  Future<PlayerProfile> updateSocialLink(
    String id, {
    required String platform,
    required String url,
  }) => _authorized((token) async {
    final json = await _remote.updateSocialLink(token, id, {
      'platform': platform,
      'url': url,
    });
    return PlayerProfileModel.fromJson(json);
  });

  @override
  Future<PlayerProfile> deleteSocialLink(String id) =>
      _authorized((token) async {
        final json = await _remote.deleteSocialLink(token, id);
        return PlayerProfileModel.fromJson(json);
      });

  @override
  Future<PlayerProfile> getPublicProfile(String id) async {
    final json = await _remote.getPublicProfile(id);
    return PlayerProfileModel.fromJson(json);
  }

  @override
  Future<List<LookupOption>> getSports() async {
    final json = await _remote.getSports();
    return json
        .map((e) => LookupOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LookupOption>> getCountries() async {
    final json = await _remote.getCountries();
    return json
        .map((e) => LookupOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepositoryImpl(
    ref.watch(playerRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
