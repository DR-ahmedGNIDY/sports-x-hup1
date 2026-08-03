import 'player_enums.dart';

class PlayerMedia {
  const PlayerMedia({
    required this.id,
    required this.type,
    required this.secureUrl,
    required this.isProfilePhoto,
  });

  final String id;
  final PlayerMediaType type;
  final String secureUrl;
  final bool isProfilePhoto;
}
