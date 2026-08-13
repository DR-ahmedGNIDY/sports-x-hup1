import 'player_enums.dart';

class PlayerMedia {
  const PlayerMedia({
    required this.id,
    required this.type,
    required this.secureUrl,
  });

  final String id;
  final PlayerMediaType type;
  final String secureUrl;
}
