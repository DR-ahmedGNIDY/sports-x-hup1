import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/club_repository_impl.dart';
import '../domain/entities/club_profile.dart';

class ClubProfileController extends AsyncNotifier<ClubProfile> {
  @override
  Future<ClubProfile> build() {
    return ref.read(clubRepositoryProvider).getMyProfile();
  }

  Future<void> saveProfile({
    String? name,
    String? country,
    String? city,
    String? description,
    int? foundedYear,
    String? level,
  }) async {
    final updated = await ref
        .read(clubRepositoryProvider)
        .updateMyProfile(
          name: name,
          country: country,
          city: city,
          description: description,
          foundedYear: foundedYear,
          level: level,
        );
    state = AsyncData(updated);
  }

  Future<void> uploadLogo({required List<int> bytes, required String filename}) async {
    final updated = await ref
        .read(clubRepositoryProvider)
        .uploadLogo(bytes: bytes, filename: filename);
    state = AsyncData(updated);
  }
}

final clubProfileControllerProvider =
    AsyncNotifierProvider<ClubProfileController, ClubProfile>(
      ClubProfileController.new,
    );
