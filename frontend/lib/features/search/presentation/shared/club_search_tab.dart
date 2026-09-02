import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_empty_state.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../club/application/club_search_controller.dart';
import '../../../club/presentation/shared/public_club_card.dart';

/// The Clubs half of the search screen: a name box and a list of clubs,
/// each opening its public profile.
///
/// A plain `ListView` rather than the sliver list the Players half uses —
/// the two halves live inside a `TabBarView`, which gives each tab its own
/// scrollable, and a sliver would need a `CustomScrollView` of its own to
/// sit in for no gain.
class ClubSearchTab extends ConsumerStatefulWidget {
  const ClubSearchTab({super.key});

  @override
  ConsumerState<ClubSearchTab> createState() => _ClubSearchTabState();
}

class _ClubSearchTabState extends ConsumerState<ClubSearchTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(clubSearchControllerProvider);
    final notifier = ref.read(clubSearchControllerProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l10n.clubSearchNameLabel,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearchLabel,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        notifier.applySearch('');
                        setState(() {});
                      },
                    ),
            ),
            // Submitted, not per-keystroke: every character would otherwise
            // be a request, and the regex behind it is an unindexed scan.
            onSubmitted: notifier.applySearch,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: resultsAsync.when(
            data: (page) => page.items.isEmpty
                ? AppEmptyState(
                    message: l10n.clubsNoResults,
                    variant: EmptyStateVariant.noResults,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount:
                        page.items.length +
                        (page.total > page.pageSize ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == page.items.length) {
                        return _Pagination(
                          page: page.page,
                          lastPage:
                              ((page.total - 1) / page.pageSize).floor() + 1,
                          onPage: notifier.loadPage,
                        );
                      }
                      return PublicClubCard(club: page.items[index]);
                    },
                  ),
            loading: () => const AppSkeletonList(),
            error: (error, _) => ErrorState(
              onRetry: () => ref.invalidate(clubSearchControllerProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.lastPage,
    required this.onPage,
  });

  final int page;
  final int lastPage;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.previousPageLabel,
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(l10n.pageOfPagesLabel(page, lastPage)),
        IconButton(
          tooltip: l10n.nextPageLabel,
          onPressed: page < lastPage ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
