import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/subscriptions_controllers.dart';
import '../data/subscriptions_repository.dart';
import '../domain/subscription.dart';
import 'subscription_form.dart';
import 'subscription_widgets.dart';

const _maxContentWidth = 720.0;

Widget _constrained(Widget child) => Align(
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _maxContentWidth),
    child: child,
  ),
);

// ------------------------------------------------------------------- club

/// `/club/subscriptions` — the whole roster with each player's latest
/// subscription, most urgent first.
class ClubSubscriptionsPage extends ConsumerWidget {
  const ClubSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(clubSubscriptionsProvider);
    final filter = ref.watch(subscriptionsFilterProvider);
    final counts = overview.valueOrNull?.counts;

    String chipLabel(String label, SubscriptionStatus? status) {
      final count = status == null
          ? counts?.values.fold<int>(0, (sum, n) => sum + n)
          : counts?[status];
      return count == null ? label : '$label ($count)';
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(clubSubscriptionsProvider.future),
      child: _constrained(
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(chipLabel(l10n.subscriptionsAll, null)),
                      selected: filter == null,
                      onSelected: (_) =>
                          ref.read(subscriptionsFilterProvider.notifier).state =
                              null,
                    ),
                    for (final status in const [
                      SubscriptionStatus.expired,
                      SubscriptionStatus.expiring,
                      SubscriptionStatus.active,
                      SubscriptionStatus.none,
                    ])
                      ChoiceChip(
                        label: Text(
                          chipLabel(
                            subscriptionStatusLabel(l10n, status),
                            status,
                          ),
                        ),
                        selected: filter == status,
                        onSelected: (_) =>
                            ref
                                    .read(subscriptionsFilterProvider.notifier)
                                    .state =
                                status,
                      ),
                  ],
                ),
              ),
            ),
            if ((overview.valueOrNull?.unpaid ?? 0) > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l10n.subscriptionsUnpaidCount(overview.value!.unpaid),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: SubscriptionAsyncBody<ClubSubscriptionsOverview>(
                value: overview,
                onRetry: () => ref.invalidate(clubSubscriptionsProvider),
                builder: (data) => data.items.isEmpty
                    ? Center(child: Text(l10n.subscriptionsEmpty))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _RosterRow(row: data.items[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.row});

  final RosterSubscription row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = row.current;
    final subtitle = <String>[
      if (current != null)
        subscriptionEndLabel(l10n, row.status, current.endDate),
      if (current != null && !current.fullyPaid)
        l10n.subscriptionPaidOf(
          subscriptionMoney(context, current.paidMinor),
          subscriptionMoney(context, current.amountMinor),
        ),
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: SubscriptionAvatar(name: row.name, photoUrl: row.photoUrl),
        title: Text(row.name.isEmpty ? l10n.unnamedPlayer : row.name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: SubscriptionStatusChip(status: row.status),
        onTap: () => context.go('/club/subscriptions/${row.playerUserId}'),
      ),
    );
  }
}

/// `/club/subscriptions/:playerUserId` — one player: the reminder actions
/// when there is something to chase, then every period with its payments.
/// A tapped expiry notification opens this page.
class ClubPlayerSubscriptionsPage extends ConsumerWidget {
  const ClubPlayerSubscriptionsPage({super.key, required this.playerUserId});

  final String playerUserId;

  Future<void> _renew(
    BuildContext context,
    WidgetRef ref,
    PlayerSubscription subscription,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subscriptionsRepositoryProvider).renew(subscription.id);
      refreshPlayerSubscriptions(ref, playerUserId);
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PlayerSubscription subscription,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.subscriptionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subscriptionsRepositoryProvider).delete(subscription.id);
      refreshPlayerSubscriptions(ref, playerUserId);
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detail = ref.watch(playerSubscriptionDetailProvider(playerUserId));

    return SubscriptionAsyncBody<PlayerSubscriptionDetail>(
      value: detail,
      onRetry: () =>
          ref.invalidate(playerSubscriptionDetailProvider(playerUserId)),
      builder: (data) {
        final current = data.current;
        final needsChasing =
            data.status == SubscriptionStatus.expired ||
            data.status == SubscriptionStatus.expiring;
        return _constrained(
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  SubscriptionAvatar(name: data.name, photoUrl: data.photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name.isEmpty ? l10n.unnamedPlayer : data.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (current != null)
                          Text(
                            subscriptionEndLabel(
                              l10n,
                              data.status,
                              current.endDate,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  SubscriptionStatusChip(status: data.status),
                ],
              ),
              const SizedBox(height: 16),
              if (needsChasing) ...[
                SubscriptionReminderActions(detail: data),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  if (current != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _renew(context, ref, current),
                        icon: const Icon(Icons.autorenew),
                        label: Text(l10n.subscriptionRenew),
                      ),
                    ),
                  if (current != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showSubscriptionForm(
                        context,
                        playerUserId: playerUserId,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.subscriptionAdd),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.subscriptionHistory, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (data.history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(l10n.subscriptionHistoryEmpty)),
                ),
              for (final subscription in data.history)
                _HistoryCard(
                  subscription: subscription,
                  onEdit: () => showSubscriptionForm(
                    context,
                    playerUserId: playerUserId,
                    existing: subscription,
                  ),
                  onDelete: () => _delete(context, ref, subscription),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  final PlayerSubscription subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notes = subscription.notes?.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscriptionPlanLabel(l10n, subscription.plan),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    l10n.subscriptionPeriod(
                      displayDate(subscription.startDate),
                      displayDate(subscription.endDate),
                    ),
                  ),
                  Text(
                    l10n.subscriptionPaidOf(
                      subscriptionMoney(context, subscription.paidMinor),
                      subscriptionMoney(context, subscription.amountMinor),
                    ),
                    style: TextStyle(
                      color: subscription.fullyPaid
                          ? null
                          : theme.colorScheme.error,
                    ),
                  ),
                  if (notes != null && notes.isNotEmpty)
                    Text(notes, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.subscriptionEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: l10n.deleteLabel,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- player

/// `/player/subscription` — the player's own latest subscription.
class MySubscriptionPage extends ConsumerWidget {
  const MySubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SubscriptionAsyncBody<MySubscription>(
      value: ref.watch(mySubscriptionProvider),
      onRetry: () => ref.invalidate(mySubscriptionProvider),
      builder: (data) {
        final current = data.current;
        if (current == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.mySubscriptionNone, textAlign: TextAlign.center),
            ),
          );
        }
        return _constrained(
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.mySubscriptionAt(data.clubName ?? ''),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          SubscriptionStatusChip(status: data.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subscriptionEndLabel(l10n, data.status, current.endDate),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(subscriptionPlanLabel(l10n, current.plan)),
                      Text(
                        l10n.subscriptionPeriod(
                          displayDate(current.startDate),
                          displayDate(current.endDate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
