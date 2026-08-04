import 'player_enums.dart';

/// Lean player summary used by both Search Players results and the Saved
/// Players list — mirrors the backend's `toSearchResultView` shape.
class PlayerSearchResult {
  const PlayerSearchResult({
    required this.id,
    this.firstName,
    this.lastName,
    this.age,
    this.country,
    this.sport,
    this.position,
    this.preferredFoot,
    this.height,
    this.weight,
    this.profilePhotoUrl,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? country;
  final String? sport;
  final String? position;
  final PreferredFoot? preferredFoot;
  final num? height;
  final num? weight;
  final String? profilePhotoUrl;

  String get fullName => [
    firstName,
    lastName,
  ].where((part) => part != null && part.isNotEmpty).join(' ');
}
