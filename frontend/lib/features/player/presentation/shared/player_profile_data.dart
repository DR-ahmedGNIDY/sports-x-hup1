// Presentation-agnostic data shaping for the Player Profile redesign —
// used identically by the desktop and mobile scouting layouts so "which
// fields are available" is decided in exactly one place. Every getter
// here only surfaces fields that already exist on [PlayerProfile]; there
// is no fabricated data (no stats, no attributes, no playing style — the
// current model doesn't have them).
import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/basketball_position.dart';
import '../../domain/entities/football_position.dart';
import '../../domain/entities/player_profile.dart';
import 'player_enum_labels.dart';

int? computeAge(DateTime? dateOfBirth) {
  if (dateOfBirth == null) return null;
  final now = DateTime.now();
  var age = now.year - dateOfBirth.year;
  if (now.month < dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
    age--;
  }
  return age;
}

String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class QuickFact {
  const QuickFact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// Age, height, weight, preferred foot, birth year — only the ones
/// actually derivable from the profile. Order matches the redesigned
/// "Quick Stats" row (Age | Height | Weight | Foot | Birth year); date of
/// birth's year is a plain `.year` read off the same `dateOfBirth` used
/// for age, not a new field, so this stays within the "no fabricated
/// data" rule above.
List<QuickFact> buildQuickFacts(AppLocalizations l10n, PlayerProfile profile) {
  final age = computeAge(profile.dateOfBirth);
  return [
    if (age != null) QuickFact(icon: Icons.cake_outlined, label: l10n.ageLabel, value: '$age'),
    if (profile.height != null)
      QuickFact(icon: Icons.height, label: l10n.heightStatLabel, value: '${profile.height} cm'),
    if (profile.weight != null)
      QuickFact(
        icon: Icons.monitor_weight_outlined,
        label: l10n.weightStatLabel,
        value: '${profile.weight} kg',
      ),
    if (profile.preferredFoot != null)
      QuickFact(
        icon: Icons.sports_soccer_outlined,
        label: l10n.preferredFootLabel,
        value: preferredFootLabel(l10n, profile.preferredFoot!),
      ),
    if (profile.dateOfBirth != null)
      QuickFact(
        icon: Icons.event_outlined,
        label: l10n.birthYearLabel,
        value: '${profile.dateOfBirth!.year}',
      ),
  ];
}

/// "Football · CM, RW" for a Football player or "Basketball · PG, SG" for
/// a Basketball player, both with parsed positions, falling back to the
/// raw `sport · position` text for any other sport (which has no position
/// enum/parser of its own), and to just the sport when there's no
/// position on file at all.
String playerPositionSummary(PlayerProfile profile) {
  final sport = profile.sport;
  if (sport == null || sport.isEmpty) return '';
  if (isFootballSport(sport)) {
    final positions = parseFootballPositions(profile.position);
    if (positions.isEmpty) return sport;
    return '$sport · ${positions.join(', ')}';
  }
  if (isBasketballSport(sport)) {
    final positions = parseBasketballPositions(profile.position);
    if (positions.isEmpty) return sport;
    return '$sport · ${positions.join(', ')}';
  }
  if (profile.position != null && profile.position!.isNotEmpty) {
    return '$sport · ${profile.position}';
  }
  return sport;
}

class ClubInfo {
  const ClubInfo({required this.name, this.status});

  final String name;
  final String? status;
}

/// The profile only stores a free-text club name + status (no club
/// object, no logo, no membership record) — this is all there is to
/// show until that data exists.
ClubInfo? currentClubInfo(PlayerProfile profile) {
  final name = profile.currentClub;
  if (name == null || name.isEmpty) return null;
  final status = profile.currentStatus;
  return ClubInfo(name: name, status: (status != null && status.isNotEmpty) ? status : null);
}
