import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_enums.dart';

/// Translates a [PreferredFoot] for display. The enum's own `.label` stays
/// a fixed English string (it's also used as the wire-adjacent constant in
/// a few places) — this is the one place a localized label is derived from
/// it, used by every dropdown/stat that shows a PreferredFoot to a user.
String preferredFootLabel(AppLocalizations l10n, PreferredFoot foot) => switch (foot) {
  PreferredFoot.left => l10n.preferredFootLeft,
  PreferredFoot.right => l10n.preferredFootRight,
  PreferredFoot.both => l10n.preferredFootBoth,
};

/// Translates a `PlayerStats.missingFields` key (from `GET
/// /players/me/stats`) for the dashboard's completion checklist. Keys are
/// a fixed backend contract — see COMPLETION_CHECKS in the backend's
/// players.mapper.ts — so this switch must stay in sync with that list.
String missingFieldLabel(AppLocalizations l10n, String key) => switch (key) {
  'firstName' => l10n.firstNameLabel,
  'lastName' => l10n.lastNameLabel,
  'dateOfBirth' => l10n.dateOfBirthLabel,
  'nationality' => l10n.nationalityLabel,
  'country' => l10n.countryLabel,
  'city' => l10n.cityLabel,
  'sport' => l10n.sportLabel,
  'position' => l10n.positionLabel,
  'bio' => l10n.bioLabel,
  'profilePhoto' => l10n.dashboardMissingProfilePhoto,
  'contact' => l10n.dashboardMissingContact,
  'achievements' => l10n.achievementsTitle,
  'socialLinks' => l10n.socialLinksTitle,
  _ => key,
};
