import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/video_repository_impl.dart';
import '../domain/entities/player_traits.dart';

/// The signed-in player's own Traits (`null` if their sport doesn't have
/// traits yet — Football-only for now). autoDispose: no reason to keep this
/// cached once no widget is watching it.
final myTraitsProvider = FutureProvider.autoDispose<PlayerTraits?>(
  (ref) => ref.watch(videoRepositoryProvider).getMyTraits(),
);

/// Another player's Traits, PUBLIC-videos-only — mirrors
/// [publicVideosProvider]'s autoDispose-per-visit shape.
final playerTraitsProvider = FutureProvider.autoDispose.family<PlayerTraits?, String>(
  (ref, playerId) => ref.watch(videoRepositoryProvider).getPlayerTraits(playerId),
);
