import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_stats.dart';

/// The overview cards' counts. Read-only and cheap, so this is a plain
/// future provider rather than a notifier — the dashboard refreshes it by
/// invalidating, which is also what the suspend/verify actions on the
/// other admin pages do so the cards never go stale behind them.
final adminStatsProvider = FutureProvider<AdminStats>(
  (ref) => ref.watch(adminRepositoryProvider).getStats(),
);
