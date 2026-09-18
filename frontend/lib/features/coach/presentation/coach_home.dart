import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/user_role.dart';
import '../../dashboard/presentation/shared/composer_card.dart';
import '../../dashboard/presentation/shared/feed_tabs.dart';
import '../../dashboard/presentation/shared/home_banner.dart';
import '../../home_feed/application/home_feed_controller.dart';
import '../../home_feed/domain/entities/feed_item.dart';
import '../../home_feed/presentation/shared/create_post_sheet.dart';
import '../../home_feed/presentation/shared/home_feed_slivers.dart';
import '../application/coach_providers.dart';
import 'club_context_gate.dart';
import 'shared/coach_widgets.dart';

/// The coach's Home: who they are and which club they are working for,
/// shortcuts to their CV and clubs, then the same post composer and feed
/// every role gets — a coach posts as themselves.
class CoachHome extends ConsumerStatefulWidget {
  const CoachHome({super.key, required this.mobile});

  /// Phone layout (collapsing app bar owned by the screen) vs desktop.
  final bool mobile;

  @override
  ConsumerState<CoachHome> createState() => _CoachHomeState();
}

class _CoachHomeState extends ConsumerState<CoachHome> {
  FeedItemKind? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(myCoachProfileProvider).valueOrNull;
    final active = ref.watch(activeClubProvider).valueOrNull;
    final gutter = widget.mobile ? AppSpacing.lg : AppSpacing.xl;
    void post() => CreatePostSheet.show(context, role: UserRole.coach);

    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeBanner(name: profile?.fullName),
              const SizedBox(height: AppSpacing.lg),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CoachAvatar(url: profile?.profilePhotoUrl, radius: 26),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (profile?.fullName.isNotEmpty ?? false)
                                  ? profile!.fullName
                                  : l10n.roleCoach,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (active != null)
                              const ActiveClubSwitcher(dense: true)
                            else
                              Text(
                                l10n.coachNoClubsYet,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          IconButton(
                            tooltip: l10n.coachMyCvNav,
                            icon: const Icon(Icons.assignment_ind_outlined),
                            onPressed: () => context.go('/coach/preview'),
                          ),
                          IconButton(
                            tooltip: l10n.coachMyClubsTitle,
                            icon: const Icon(Icons.shield_outlined),
                            onPressed: () => context.go('/coach/clubs'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.dashboardLatestNewsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ComposerCard(
                logoUrl: profile?.profilePhotoUrl,
                isClub: false,
                onTap: post,
              ),
              const SizedBox(height: AppSpacing.md),
              FeedTabs(
                value: _filter,
                onChanged: (kind) => setState(() => _filter = kind),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
      HomeFeedSliver(
        kindFilter: _filter,
        onCreatePost: post,
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
      ),
    ];

    Future<void> refresh() async {
      ref.invalidate(myCoachClubsProvider);
      await ref.read(homeFeedControllerProvider.notifier).refresh();
    }

    if (widget.mobile) {
      return AppScaffoldMobile(onRefresh: refresh, slivers: slivers);
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(slivers: slivers),
    );
  }
}
