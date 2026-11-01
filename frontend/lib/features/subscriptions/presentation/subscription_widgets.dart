import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../club/application/club_profile_controller.dart';
import '../../store/presentation/widgets/money.dart';
import '../data/subscriptions_repository.dart';
import '../domain/subscription.dart';

String subscriptionStatusLabel(
  AppLocalizations l10n,
  SubscriptionStatus status,
) => switch (status) {
  SubscriptionStatus.active => l10n.subscriptionStatusActive,
  SubscriptionStatus.expiring => l10n.subscriptionStatusExpiring,
  SubscriptionStatus.expired => l10n.subscriptionStatusExpired,
  SubscriptionStatus.none => l10n.subscriptionStatusNone,
};

String subscriptionPlanLabel(AppLocalizations l10n, SubscriptionPlan plan) =>
    switch (plan) {
      SubscriptionPlan.monthly => l10n.subscriptionPlanMonthly,
      SubscriptionPlan.quarterly => l10n.subscriptionPlanQuarterly,
      SubscriptionPlan.custom => l10n.subscriptionPlanCustom,
    };

String subscriptionMoney(BuildContext context, int minor) => formatMoney(
  minor,
  isArabic: Localizations.localeOf(context).languageCode == 'ar',
);

/// "Ends …" / "Ended …" for a subscription's last day.
String subscriptionEndLabel(
  AppLocalizations l10n,
  SubscriptionStatus status,
  String endDate,
) => status == SubscriptionStatus.expired
    ? l10n.subscriptionEndedOn(displayDate(endDate))
    : l10n.subscriptionEndsOn(displayDate(endDate));

class SubscriptionStatusChip extends StatelessWidget {
  const SubscriptionStatusChip({super.key, required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      SubscriptionStatus.active => (
        Colors.green.withValues(alpha: 0.14),
        Colors.green.shade800,
      ),
      SubscriptionStatus.expiring => (
        Colors.orange.withValues(alpha: 0.16),
        Colors.orange.shade900,
      ),
      SubscriptionStatus.expired => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      SubscriptionStatus.none => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        subscriptionStatusLabel(AppLocalizations.of(context)!, status),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

/// The club's two ways of asking a player to renew, side by side: a
/// WhatsApp message it can still edit before sending, and an in-app
/// notification that also reaches the player's phone when they enabled
/// pushes. Shown on the player's subscription page, which is also where a
/// tapped expiry notification lands.
class SubscriptionReminderActions extends ConsumerStatefulWidget {
  const SubscriptionReminderActions({super.key, required this.detail});

  final PlayerSubscriptionDetail detail;

  @override
  ConsumerState<SubscriptionReminderActions> createState() =>
      _SubscriptionReminderActionsState();
}

class _SubscriptionReminderActionsState
    extends ConsumerState<SubscriptionReminderActions> {
  bool _sending = false;

  Future<void> _openWhatsApp(AppLocalizations l10n) async {
    final detail = widget.detail;
    final current = detail.current;
    final phone = detail.whatsAppPhone;
    if (current == null || phone == null) return;

    final clubName =
        ref.read(clubProfileControllerProvider).valueOrNull?.name ?? '';
    final name = detail.firstName?.trim().isNotEmpty == true
        ? detail.firstName!.trim()
        : detail.name;
    final date = displayDate(current.endDate);
    final message = detail.status == SubscriptionStatus.expired
        ? l10n.subscriptionWhatsAppExpired(name, clubName, date)
        : l10n.subscriptionWhatsAppExpiring(name, clubName, date);
    await launchUrl(
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _remindInApp(AppLocalizations l10n) async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(subscriptionsRepositoryProvider)
          .remind(widget.detail.playerUserId);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.subscriptionReminderSent)),
      );
    } on AppException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.statusCode == 429
                ? l10n.subscriptionReminderAlreadyToday
                : error.message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasPhone = widget.detail.whatsAppPhone != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.subscriptionRemindTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: hasPhone ? () => _openWhatsApp(l10n) : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: const Color(0xFF04110E),
              ),
              icon: const Icon(Icons.chat_outlined),
              label: Text(l10n.subscriptionRemindWhatsApp),
            ),
            if (!hasPhone)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.subscriptionNoPhone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _sending ? null : () => _remindInApp(l10n),
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.subscriptionRemindInApp),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar with the player's photo, or their initial.
class SubscriptionAvatar extends StatelessWidget {
  const SubscriptionAvatar({super.key, required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return CircleAvatar(
      backgroundImage: url == null ? null : NetworkImage(url),
      child: url == null
          ? Text(name.isEmpty ? '?' : name.characters.first.toUpperCase())
          : null,
    );
  }
}

/// The shared loading / error shell, so each page only describes its data.
class SubscriptionAsyncBody<T> extends StatelessWidget {
  const SubscriptionAsyncBody({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is AppException
                    ? error.message
                    : l10n.genericErrorMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.retryButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
