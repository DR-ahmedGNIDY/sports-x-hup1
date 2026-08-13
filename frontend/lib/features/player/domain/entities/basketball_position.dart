import 'dart:ui' show Offset;

import '../../../../l10n/generated/app_localizations.dart';

/// A single marker slot on the basketball half-court diagram. Unlike
/// football, every code here is unique (no shared slots), but the shape
/// mirrors [FootballPositionMarker]-equivalent so the two visualizations
/// stay structurally consistent.
class BasketballPositionMarker {
  const BasketballPositionMarker({required this.id, required this.code, required this.location});

  /// Unique per marker.
  final String id;

  /// The short code shown on the marker and matched against the player's
  /// free-text `position` field (e.g. `PG`, `C`).
  final String code;

  /// Normalized position within the canonical half-court, `0..1` on both
  /// axes. `y = 0` is the center line (top), `y = 1` is the baseline /
  /// basket end.
  final Offset location;
}

String basketballPositionFullName(AppLocalizations l10n, String code) => switch (code) {
  'PG' => l10n.basketballPositionPg,
  'SG' => l10n.basketballPositionSg,
  'SF' => l10n.basketballPositionSf,
  'PF' => l10n.basketballPositionPf,
  'C' => l10n.basketballPositionC,
  _ => code,
};

String basketballPositionDescription(AppLocalizations l10n, String code) => switch (code) {
  'PG' => l10n.basketballPositionPgDesc,
  'SG' => l10n.basketballPositionSgDesc,
  'SF' => l10n.basketballPositionSfDesc,
  'PF' => l10n.basketballPositionPfDesc,
  'C' => l10n.basketballPositionCDesc,
  _ => '',
};

/// The 5 markers drawn on the half-court, as approximate tactical zones —
/// not fixed player locations. PG anchors the top of the perimeter, SG/SF
/// take the wings, PF sits in the low post short-corner, and C occupies
/// the paint closest to the basket.
const List<BasketballPositionMarker> basketballPositionMarkers = [
  BasketballPositionMarker(id: 'pg', code: 'PG', location: Offset(0.5, 0.32)),
  BasketballPositionMarker(id: 'sg', code: 'SG', location: Offset(0.84, 0.46)),
  BasketballPositionMarker(id: 'sf', code: 'SF', location: Offset(0.16, 0.46)),
  BasketballPositionMarker(id: 'pf', code: 'PF', location: Offset(0.30, 0.80)),
  BasketballPositionMarker(id: 'c', code: 'C', location: Offset(0.5, 0.92)),
];

const List<String> basketballPositionCodes = ['PG', 'SG', 'SF', 'PF', 'C'];

/// Synonyms accepted when parsing the free-text `position` field, so
/// players who typed "Point Guard" or "Center" instead of a short code
/// still get the right marker highlighted.
const Map<String, String> _basketballPositionSynonyms = {
  'POINT GUARD': 'PG',
  'SHOOTING GUARD': 'SG',
  'SMALL FORWARD': 'SF',
  'POWER FORWARD': 'PF',
  'CENTER': 'C',
  'CENTRE': 'C',
  'GUARD': 'PG',
  'FORWARD': 'SF',
};

/// Parses the player's free-text `position` field into known position
/// codes. The field has no enum backing it (see [BasketballPositionMarker]
/// doc), so this is intentionally tolerant: it splits on common
/// separators, normalizes each token, and drops anything unrecognized.
/// The first recognized code is the primary position; the rest are
/// secondary.
List<String> parseBasketballPositions(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final tokens = raw.split(RegExp(r'[,/&]|\band\b', caseSensitive: false));
  final codes = <String>[];
  for (final token in tokens) {
    final normalized = token.trim().toUpperCase();
    if (normalized.isEmpty) continue;
    final code = basketballPositionCodes.contains(normalized)
        ? normalized
        : _basketballPositionSynonyms[normalized];
    if (code != null && !codes.contains(code)) codes.add(code);
  }
  return codes;
}

/// Joins parsed codes back into the single free-text string stored on the
/// profile, preserving primary-first order.
String formatBasketballPositions(List<String> codes) => codes.join(', ');

/// Whether the Basketball Position Visualization should render at all —
/// the court is Basketball-only, per product spec.
bool isBasketballSport(String? sport) => sport?.trim().toLowerCase() == 'basketball';
