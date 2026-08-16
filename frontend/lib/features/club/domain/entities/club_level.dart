/// Controlled values for [ClubProfile.level] — mirrors the backend's
/// `ClubLevel` enum (`backend/src/clubs/club-level.enum.ts`). Stable,
/// language-independent wire values; [clubLevelLabel] (in
/// `presentation/shared/club_level_labels.dart`) maps these to a
/// localized display string.
enum ClubLevel {
  amateur('amateur'),
  semiProfessional('semi_professional'),
  professional('professional');

  const ClubLevel(this.wireValue);

  final String wireValue;

  /// `null` when [value] doesn't match any known value — a club profile
  /// saved before this enum existed may still carry old free-text (e.g.
  /// "احترافي" typed directly). Callers must handle that case themselves
  /// (see `club_info_section.dart`) rather than crashing on legacy data.
  static ClubLevel? fromWire(String? value) {
    if (value == null) return null;
    for (final level in ClubLevel.values) {
      if (level.wireValue == value) return level;
    }
    return null;
  }
}
