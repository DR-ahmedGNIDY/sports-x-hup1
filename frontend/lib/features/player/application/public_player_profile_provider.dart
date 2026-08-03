import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/player_profile.dart';

// autoDispose: each id is a one-off page visit, not reusable reference
// data — without this, every public profile a Club browses (Phase 3
// search) would stay cached for the rest of the session.
final publicPlayerProfileProvider =
    FutureProvider.autoDispose.family<PlayerProfile, String>(
      (ref, id) => ref.watch(playerRepositoryProvider).getPublicProfile(id),
    );
