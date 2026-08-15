import '../../../player/domain/entities/player_profile.dart';

/// Whether a club-managed player's profile is "complete" — mirrors the
/// backend's own checklist (`players.mapper.ts` `COMPLETION_CHECKS`)
/// closely enough to classify players for the Club Dashboard's
/// complete/incomplete summary, using only fields already returned by
/// `GET /club-players` (no extra request, no invented data).
bool isClubPlayerProfileComplete(PlayerProfile profile) {
  return (profile.firstName?.isNotEmpty ?? false) &&
      (profile.lastName?.isNotEmpty ?? false) &&
      profile.dateOfBirth != null &&
      (profile.nationality?.isNotEmpty ?? false) &&
      (profile.country?.isNotEmpty ?? false) &&
      (profile.city?.isNotEmpty ?? false) &&
      (profile.sport?.isNotEmpty ?? false) &&
      (profile.position?.isNotEmpty ?? false) &&
      (profile.bio?.isNotEmpty ?? false) &&
      profile.profilePhoto != null &&
      !profile.contact.isEmpty;
}
