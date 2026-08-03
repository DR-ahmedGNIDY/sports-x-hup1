import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/contact_details.dart';
import '../domain/entities/player_enums.dart';
import '../domain/entities/player_profile.dart';

/// Owns the signed-in Player's own profile — the single source of truth
/// consumed by Edit Profile and My Profile Preview. Every mutation calls
/// the backend (which returns the full updated profile) and replaces
/// state with that response, so the UI never has to reconcile a partial
/// local edit against server state.
class PlayerProfileController extends AsyncNotifier<PlayerProfile> {
  @override
  Future<PlayerProfile> build() {
    return ref.read(playerRepositoryProvider).getMyProfile();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> saveProfile({
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
  }) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .updateMyProfile(
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          nationality: nationality,
          country: country,
          city: city,
          sport: sport,
          position: position,
          preferredFoot: preferredFoot,
          height: height,
          weight: weight,
          currentStatus: currentStatus,
          currentClub: currentClub,
          bio: bio,
          contact: contact,
        );
    state = AsyncData(updated);
  }

  Future<void> setVisibility(ProfileVisibility visibility) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .updateVisibility(visibility);
    state = AsyncData(updated);
  }

  Future<void> uploadMedia({
    required List<int> bytes,
    required String filename,
    required PlayerMediaType type,
    bool isProfilePhoto = false,
  }) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .uploadMedia(
          bytes: bytes,
          filename: filename,
          type: type,
          isProfilePhoto: isProfilePhoto,
        );
    state = AsyncData(updated);
  }

  Future<void> deleteMedia(String mediaId) async {
    final updated = await ref.read(playerRepositoryProvider).deleteMedia(mediaId);
    state = AsyncData(updated);
  }

  Future<void> addAchievement({
    required String title,
    required int year,
    String? description,
  }) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .addAchievement(title: title, year: year, description: description);
    state = AsyncData(updated);
  }

  Future<void> updateAchievement(
    String id, {
    String? title,
    int? year,
    String? description,
  }) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .updateAchievement(id, title: title, year: year, description: description);
    state = AsyncData(updated);
  }

  Future<void> deleteAchievement(String id) async {
    final updated = await ref.read(playerRepositoryProvider).deleteAchievement(id);
    state = AsyncData(updated);
  }

  Future<void> addSocialLink({required String platform, required String url}) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .addSocialLink(platform: platform, url: url);
    state = AsyncData(updated);
  }

  Future<void> updateSocialLink(
    String id, {
    required String platform,
    required String url,
  }) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .updateSocialLink(id, platform: platform, url: url);
    state = AsyncData(updated);
  }

  Future<void> deleteSocialLink(String id) async {
    final updated = await ref.read(playerRepositoryProvider).deleteSocialLink(id);
    state = AsyncData(updated);
  }
}

final playerProfileControllerProvider =
    AsyncNotifierProvider<PlayerProfileController, PlayerProfile>(
      PlayerProfileController.new,
    );
