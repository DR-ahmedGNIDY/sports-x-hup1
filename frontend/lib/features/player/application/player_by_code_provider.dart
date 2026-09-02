import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/player_profile.dart';

/// `GET /players/by-code/:code` — the lookup behind "invite by player
/// code". autoDispose for the same reason as [publicPlayerProfileProvider]:
/// a code someone typed once is a one-off, not reference data.
///
/// The backend does its own normalization, but the code is trimmed and
/// upper-cased before it leaves here anyway — otherwise "ply-000123 " and
/// "PLY-000123" would be two cache keys for one player, and the second
/// lookup would spend a request proving what the first already knew.
final playerByCodeProvider = FutureProvider.autoDispose.family<PlayerProfile, String>(
  (ref, code) =>
      ref.watch(playerRepositoryProvider).getPublicProfileByCode(normalizePublicCode(code)),
);

String normalizePublicCode(String code) => code.trim().toUpperCase();
