import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/contact_details.dart';

/// Simple Contact (Phase 3). Only meaningful for an authenticated Club —
/// callers should gate watching this on the viewer's role, since the
/// backend rejects anyone else with 403.
final playerContactProvider = FutureProvider.autoDispose.family<ContactDetails, String>(
  (ref, playerId) => ref.watch(playerRepositoryProvider).getContact(playerId),
);
