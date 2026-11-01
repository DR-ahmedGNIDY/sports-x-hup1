import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscriptions_repository.dart';
import '../domain/subscription.dart';

/// The status chip the club has selected; null is "All".
final subscriptionsFilterProvider = StateProvider<SubscriptionStatus?>(
  (ref) => null,
);

/// Re-fetched whenever the filter changes. Every mutation elsewhere
/// invalidates this rather than patching it: counts, ordering and status all
/// move together, and the server already computes them.
final clubSubscriptionsProvider = FutureProvider<ClubSubscriptionsOverview>(
  (ref) => ref
      .watch(subscriptionsRepositoryProvider)
      .overview(status: ref.watch(subscriptionsFilterProvider)),
);

final playerSubscriptionDetailProvider = FutureProvider.autoDispose
    .family<PlayerSubscriptionDetail, String>(
      (ref, playerUserId) =>
          ref.watch(subscriptionsRepositoryProvider).player(playerUserId),
    );

final mySubscriptionProvider = FutureProvider.autoDispose<MySubscription>(
  (ref) => ref.watch(subscriptionsRepositoryProvider).mine(),
);

/// After any change to one player's subscriptions: their page and the list.
void refreshPlayerSubscriptions(WidgetRef ref, String playerUserId) {
  ref.invalidate(playerSubscriptionDetailProvider(playerUserId));
  ref.invalidate(clubSubscriptionsProvider);
}
