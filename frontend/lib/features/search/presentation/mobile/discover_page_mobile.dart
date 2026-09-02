import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../shared/club_search_tab.dart';
import 'search_players_page_mobile.dart';

/// The Player's Search tab: other players, or clubs.
///
/// Two tabs rather than one blended list. A player result and a club result
/// answer different questions — "who else plays" and "where could I play" —
/// and interleaving them would make both harder to scan while forcing a
/// single ranking on two things that cannot be ranked against each other.
///
/// The Players half is the same screen a Club uses, reused whole rather
/// than reimplemented: it already has the filters, the pagination and the
/// result card, and a second copy would drift from it within a release.
class DiscoverPageMobile extends StatelessWidget {
  const DiscoverPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Below the app bar rather than inside it: this screen's bar is
          // AppScaffoldMobile's, owned by the Players tab, and a bar cannot
          // hold a control belonging to the thing it contains.
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                tabs: [
                  Tab(text: l10n.marketingNavPlayers),
                  Tab(text: l10n.marketingNavClubs),
                ],
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [SearchPlayersPageMobile(), ClubSearchTab()],
            ),
          ),
        ],
      ),
    );
  }
}
