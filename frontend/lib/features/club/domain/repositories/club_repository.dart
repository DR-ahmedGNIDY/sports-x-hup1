import '../entities/club_list_page.dart';
import '../entities/club_profile.dart';

/// All methods throw [AppException] (core/errors) on failure.
abstract class ClubRepository {
  /// Public Clubs listing (Phase 5) — no auth required.
  Future<ClubListPage> listClubs({int page = 1, String? country});

  /// Public club profile (Phase 5) — no auth required.
  Future<ClubProfile> getById(String id);

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
