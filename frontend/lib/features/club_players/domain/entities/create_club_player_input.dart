import '../../../player/domain/entities/player_enums.dart';

/// Everything a club fills in on the Add Player form. `phone` is the local
/// number only (no dial code, no leading 0) and `countryIsoCode` (e.g.
/// "EG") is what the backend uses to resolve the dial code — no password
/// field, since it's always server-generated.
class CreateClubPlayerInput {
  const CreateClubPlayerInput({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.countryIsoCode,
    this.email,
    this.dateOfBirth,
    this.nationality,
    this.country,
    this.city,
    this.sport,
    this.position,
    this.preferredFoot,
    this.height,
    this.weight,
    this.currentStatus,
    this.currentClub,
    this.bio,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String countryIsoCode;
  final String? email;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? country;
  final String? city;
  final String? sport;
  final String? position;
  final PreferredFoot? preferredFoot;
  final num? height;
  final num? weight;
  final String? currentStatus;
  final String? currentClub;
  final String? bio;
}
