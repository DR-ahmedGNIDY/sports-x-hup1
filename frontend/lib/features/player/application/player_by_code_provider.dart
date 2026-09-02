import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../invitations/domain/public_code.dart';
import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/player_profile.dart';

/// `GET /players/by-code/:code` — the lookup behind "invite by player
/// code". autoDispose for the same reason as [publicPlayerProfileProvider]:
/// a code someone typed once is a one-off, not reference data.
final playerByCodeProvider = FutureProvider.autoDispose.family<PlayerProfile, String>(
  (ref, code) =>
      ref.watch(playerRepositoryProvider).getPublicProfileByCode(normalizePublicCode(code)),
);
