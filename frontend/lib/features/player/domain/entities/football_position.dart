import 'dart:ui' show Offset;

import '../../../../l10n/generated/app_localizations.dart';

/// A single marker slot on the football pitch diagram. Two markers can
/// share the same [code] (the two centre-back slots both use `CB`) — a
/// player whose position text matches that code has every marker with
/// that code highlighted, not just one.
class FootballPositionMarker {
  const FootballPositionMarker({required this.id, required this.code, required this.location});

  /// Unique per marker (e.g. the two CB slots are `cb-left` / `cb-right`).
  final String id;

  /// The short code shown on the marker and matched against the player's
  /// free-text `position` field (e.g. `CB`, `GK`, `ST`).
  final String code;

  /// Normalized position within the canonical portrait pitch, `0..1` on
  /// both axes. `y = 0` is the attacking end (forwards), `y = 1` is the
  /// goalkeeper's end.
  final Offset location;
}

String footballPositionFullName(AppLocalizations l10n, String code) => switch (code) {
  'GK' => l10n.footballPositionGk,
  'LB' => l10n.footballPositionLb,
  'CB' => l10n.footballPositionCb,
  'RB' => l10n.footballPositionRb,
  'CDM' => l10n.footballPositionCdm,
  'CM' => l10n.footballPositionCm,
  'CAM' => l10n.footballPositionCam,
  'LW' => l10n.footballPositionLw,
  'RW' => l10n.footballPositionRw,
  'ST' => l10n.footballPositionSt,
  'CF' => l10n.footballPositionCf,
  _ => code,
};

String footballPositionDescription(AppLocalizations l10n, String code) => switch (code) {
  'GK' => l10n.footballPositionGkDesc,
  'LB' => l10n.footballPositionLbDesc,
  'CB' => l10n.footballPositionCbDesc,
  'RB' => l10n.footballPositionRbDesc,
  'CDM' => l10n.footballPositionCdmDesc,
  'CM' => l10n.footballPositionCmDesc,
  'CAM' => l10n.footballPositionCamDesc,
  'LW' => l10n.footballPositionLwDesc,
  'RW' => l10n.footballPositionRwDesc,
  'ST' => l10n.footballPositionStDesc,
  'CF' => l10n.footballPositionCfDesc,
  _ => '',
};

/// The 12 markers drawn on the pitch, in a realistic top-down formation
/// layout (own goal at the bottom, near the GK; opponent's goal at the
/// top, near the forwards).
const List<FootballPositionMarker> footballPositionMarkers = [
  FootballPositionMarker(id: 'gk', code: 'GK', location: Offset(0.5, 0.93)),
  FootballPositionMarker(id: 'lb', code: 'LB', location: Offset(0.13, 0.78)),
  FootballPositionMarker(id: 'cb-left', code: 'CB', location: Offset(0.36, 0.81)),
  FootballPositionMarker(id: 'cb-right', code: 'CB', location: Offset(0.64, 0.81)),
  FootballPositionMarker(id: 'rb', code: 'RB', location: Offset(0.87, 0.78)),
  FootballPositionMarker(id: 'cdm', code: 'CDM', location: Offset(0.5, 0.62)),
  FootballPositionMarker(id: 'cm', code: 'CM', location: Offset(0.5, 0.47)),
  FootballPositionMarker(id: 'cam', code: 'CAM', location: Offset(0.5, 0.32)),
  FootballPositionMarker(id: 'lw', code: 'LW', location: Offset(0.15, 0.19)),
  FootballPositionMarker(id: 'rw', code: 'RW', location: Offset(0.85, 0.19)),
  FootballPositionMarker(id: 'cf', code: 'CF', location: Offset(0.5, 0.2)),
  FootballPositionMarker(id: 'st', code: 'ST', location: Offset(0.5, 0.07)),
];

const List<String> footballPositionCodes = [
  'GK',
  'LB',
  'CB',
  'RB',
  'CDM',
  'CM',
  'CAM',
  'LW',
  'RW',
  'ST',
  'CF',
];

/// Synonyms accepted when parsing the free-text `position` field, so
/// players who typed "Striker" or "Centre Back" instead of a short code
/// still get the right marker highlighted.
const Map<String, String> _footballPositionSynonyms = {
  'GOALKEEPER': 'GK',
  'KEEPER': 'GK',
  'LEFT BACK': 'LB',
  'LEFTBACK': 'LB',
  'CENTRE BACK': 'CB',
  'CENTER BACK': 'CB',
  'CENTREBACK': 'CB',
  'CENTERBACK': 'CB',
  'RIGHT BACK': 'RB',
  'RIGHTBACK': 'RB',
  'DEFENSIVE MIDFIELD': 'CDM',
  'DEFENSIVE MIDFIELDER': 'CDM',
  'HOLDING MIDFIELDER': 'CDM',
  'CENTRAL MIDFIELD': 'CM',
  'CENTRAL MIDFIELDER': 'CM',
  'MIDFIELDER': 'CM',
  'ATTACKING MIDFIELD': 'CAM',
  'ATTACKING MIDFIELDER': 'CAM',
  'LEFT WING': 'LW',
  'LEFT WINGER': 'LW',
  'RIGHT WING': 'RW',
  'RIGHT WINGER': 'RW',
  'STRIKER': 'ST',
  'CENTRE FORWARD': 'CF',
  'CENTER FORWARD': 'CF',
  'FORWARD': 'CF',
};

/// Parses the player's free-text `position` field into known position
/// codes. The field has no enum backing it (see [FootballPositionMarker]
/// doc), so this is intentionally tolerant: it splits on common
/// separators, normalizes each token, and drops anything unrecognized.
/// The first recognized code is the primary position; the rest are
/// secondary.
List<String> parseFootballPositions(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final tokens = raw.split(RegExp(r'[,/&]|\band\b', caseSensitive: false));
  final codes = <String>[];
  for (final token in tokens) {
    final normalized = token.trim().toUpperCase();
    if (normalized.isEmpty) continue;
    final code = footballPositionCodes.contains(normalized)
        ? normalized
        : _footballPositionSynonyms[normalized];
    if (code != null && !codes.contains(code)) codes.add(code);
  }
  return codes;
}

/// Joins parsed codes back into the single free-text string stored on the
/// profile, preserving primary-first order.
String formatFootballPositions(List<String> codes) => codes.join(', ');

/// Whether the Football Position Visualization should render at all —
/// the pitch is Football-only, per product spec.
bool isFootballSport(String? sport) => sport?.trim().toLowerCase() == 'football';
