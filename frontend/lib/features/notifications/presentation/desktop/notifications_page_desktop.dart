import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/notifications_controller.dart';
import '../shared/notifications_body.dart';
import '../shared/push_prompt_card.dart';

class NotificationsPageDesktop extends ConsumerWidget {
  const NotificationsPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(notificationsListProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.notificationsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: listAsync.when(
                  data: (page) => page.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const EmptyStateIllustration(
                                variant: EmptyStateVariant.noData,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(l10n.notificationsEmpty),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            const PushPromptCard(),
                            NotificationsToolbar(page: page),
                            const SizedBox(height: AppSpacing.sm),
                            ...notificationRows(page),
                            NotificationsPagination(page: page),
                          ],
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(
                    onRetry: () => ref.invalidate(notificationsListProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
