import '../../../player/data/models/player_profile_model.dart';
import '../../domain/entities/club_managed_player.dart';
import '../../domain/entities/club_player_credentials.dart';

extension ClubManagedPlayerModel on ClubManagedPlayer {
  /// The backend's owner view (toOwnerView) plus `userId` and `dialCode`
  /// in the same flat JSON object — PlayerProfileModel only reads the keys
  /// it knows about, so it can parse the same map.
  static ClubManagedPlayer fromJson(Map<String, dynamic> json) {
    return ClubManagedPlayer(
      userId: json['userId'] as String,
      dialCode: json['dialCode'] as String,
      profile: PlayerProfileModel.fromJson(json),
    );
  }
}

extension ClubPlayerCredentialsModel on ClubPlayerCredentials {
  static ClubPlayerCredentials fromJson(Map<String, dynamic> json) {
    return ClubPlayerCredentials(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}

Map<String, dynamic> createClubPlayerInputToJson({
  required String firstName,
  required String lastName,
  required String phone,
  required String countryIsoCode,
  String? email,
  DateTime? dateOfBirth,
  String? nationality,
  String? country,
  String? city,
  String? sport,
  String? position,
  String? preferredFoot,
  num? height,
  num? weight,
  String? currentStatus,
  String? currentClub,
  String? bio,
}) {
  return {
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'countryIsoCode': countryIsoCode,
    'email': ?email,
    'dateOfBirth': ?dateOfBirth?.toIso8601String(),
    'nationality': ?nationality,
    'country': ?country,
    'city': ?city,
    'sport': ?sport,
    'position': ?position,
    'preferredFoot': ?preferredFoot,
    'height': ?height,
    'weight': ?weight,
    'currentStatus': ?currentStatus,
    'currentClub': ?currentClub,
    'bio': ?bio,
  };
}
