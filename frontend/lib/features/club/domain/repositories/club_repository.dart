import '../entities/club_profile.dart';

/// All methods throw [AppException] (core/errors) on failure.
abstract class ClubRepository {
  Future<ClubProfile> getMyProfile();

  Future<ClubProfile> updateMyProfile({
    String? name,
    String? country,
    String? city,
    String? description,
    int? foundedYear,
    String? level,
  });

  Future<ClubProfile> uploadLogo({required List<int> bytes, required String filename});
}
