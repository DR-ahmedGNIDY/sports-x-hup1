import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/club_level.dart';

/// Translates a [ClubLevel] for display — the one place a localized label
/// is derived from the wire value, used by both the edit dropdown and the
/// read-only profile views.
String clubLevelLabel(AppLocalizations l10n, ClubLevel level) => switch (level) {
  ClubLevel.amateur => l10n.clubLevelAmateur,
  ClubLevel.semiProfessional => l10n.clubLevelSemiProfessional,
  ClubLevel.professional => l10n.clubLevelProfessional,
};

/// Same, but for a raw `ClubProfile.level` string — a controlled value is
/// localized as usual; anything else (legacy free text from before this
/// enum existed, or `null`) is shown exactly as stored. Used by read-only
/// views ([ClubProfileView]) so old data never disappears or crashes.
String? clubLevelDisplayValue(AppLocalizations l10n, String? rawLevel) {
  if (rawLevel == null || rawLevel.isEmpty) return null;
  final known = ClubLevel.fromWire(rawLevel);
  return known != null ? clubLevelLabel(l10n, known) : rawLevel;
}
