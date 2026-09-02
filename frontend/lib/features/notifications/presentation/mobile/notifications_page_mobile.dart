import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_empty_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/notifications_controller.dart';
import '../shared/notifications_body.dart';
import '../shared/push_prompt_card.dart';

class NotificationsPageMobile extends ConsumerWidget {
  const NotificationsPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(notificationsListProvider);

    return AppScaffoldMobile(
      onRefresh: () async {
        ref.invalidate(notificationsListProvider);
        ref.invalidate(unreadNotificationsProvider);
      },
      slivers: [
        listAsync.when(
          data: (page) => page.items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(message: l10n.notificationsEmpty),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.list(
                    children: [
                      const PushPromptCard(),
                      NotificationsToolbar(page: page),
                      const SizedBox(height: AppSpacing.sm),
                      ...notificationRows(page),
                      NotificationsPagination(page: page),
                    ],
                  ),
                ),
          loading: () => const SliverToBoxAdapter(
            child: AppSkeletonList(itemCount: 5, itemHeight: 72),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () => ref.invalidate(notificationsListProvider),
            ),
          ),
        ),
      ],
    );
  }
}
