/// A single skill-category rating (0-99, like a game attribute) — entirely
/// derived from the player's own uploaded videos in that category, never
/// self-entered. See `VideosService.traitsForPlayer` on the backend for the
/// exact formula.
class PlayerTrait {
  const PlayerTrait({
    required this.category,
    required this.score,
    required this.videoCount,
  });

  final String category;
  final double score;
  final int videoCount;
}

/// Football-only for now — every other sport's skill categories don't map
/// to a recognizable "trait" taxonomy yet.
class PlayerTraits {
  const PlayerTraits({required this.sport, required this.traits});

  final String sport;
  final List<PlayerTrait> traits;
}
