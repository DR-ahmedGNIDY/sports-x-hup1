import '../entities/contact_details.dart';
import '../entities/lookup_option.dart';
import '../entities/player_enums.dart';
import '../entities/player_profile.dart';
import '../entities/player_stats.dart';

/// All methods throw [AppException] (core/errors) on failure.
abstract class PlayerRepository {
  Future<PlayerProfile> getMyProfile();

  /// Powers the Player Dashboard's completion card and quick-stats tiles.
  Future<PlayerStats> getMyStats();

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
  });

  Future<PlayerProfile> updateVisibility(ProfileVisibility visibility);

  Future<PlayerProfile> uploadMedia({
    required List<int> bytes,
    required String filename,
    required PlayerMediaType type,
  });

  Future<PlayerProfile> deleteMedia(String mediaId);

  Future<PlayerProfile> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  });

  Future<PlayerProfile> deleteProfilePhoto();

  Future<PlayerProfile> addAchievement({
    required String title,
    required int year,
    String? description,
  });

  Future<PlayerProfile> updateAchievement(
    String id, {
    String? title,
    int? year,
    String? description,
  });

  Future<PlayerProfile> deleteAchievement(String id);

  Future<PlayerProfile> addSocialLink({required String platform, required String url});

  Future<PlayerProfile> updateSocialLink(
    String id, {
    required String platform,
    required String url,
  });

  Future<PlayerProfile> deleteSocialLink(String id);

  Future<PlayerProfile> getPublicProfile(String id);

  /// Simple Contact (Phase 3) — CLUB-only, 404s if the caller isn't a Club
  /// or the player isn't public.
  Future<ContactDetails> getContact(String id);

  Future<List<LookupOption>> getSports();

  Future<List<LookupOption>> getCountries();
}
