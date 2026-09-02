import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/entities/user_role.dart';
import 'desktop/discover_page_desktop.dart';
import 'desktop/search_players_page_desktop.dart';
import 'mobile/discover_page_mobile.dart';
import 'mobile/search_players_page_mobile.dart';

/// `/search`, which means something different to each role.
///
/// A Club searches players — that is the whole job, and its screen is
/// unchanged. A Player is looking for peers *or* for somewhere to play, so
/// theirs adds a Clubs tab around the same player search.
///
/// One route rather than two: it is "Search" in both navigations, and a
/// second path would mean a second tab, a second set of route metadata, and
/// a rule about which role may visit which — for what is, from the user's
/// side, the same button.
class SearchPlayersPage extends ConsumerWidget {
  const SearchPlayersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayer =
        ref.watch(sessionControllerProvider).user?.role == UserRole.player;

    return ResponsiveLayout(
      desktop: (context) => isPlayer
          ? const DiscoverPageDesktop()
          : const SearchPlayersPageDesktop(),
      mobile: (context) => isPlayer
          ? const DiscoverPageMobile()
          : const SearchPlayersPageMobile(),
    );
  }
}
