import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/club_search_tab.dart';
import 'search_players_page_desktop.dart';

/// The desktop half of the Player's Search tab — same two tabs as mobile.
/// See [DiscoverPageMobile] for why players and clubs are separated rather
/// than blended into one list.
class DiscoverPageDesktop extends StatelessWidget {
  const DiscoverPageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.marketingNavPlayers),
                  Tab(text: l10n.marketingNavClubs),
                ],
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [SearchPlayersPageDesktop(), ClubSearchTab()],
            ),
          ),
        ],
      ),
    );
  }
}
