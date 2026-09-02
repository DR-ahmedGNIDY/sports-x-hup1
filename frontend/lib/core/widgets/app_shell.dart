import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/club/application/club_profile_controller.dart';
import '../../features/player/application/player_profile_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../locale/language_toggle_button.dart';
import '../../features/notifications/presentation/shared/notification_bell.dart';
import '../navigation/app_branches.dart';
import '../theme/app_blur.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_mode_provider.dart';
import '../utils/app_haptics.dart';
import '../utils/app_image.dart';
import '../utils/app_install.dart';
import '../utils/breakpoints.dart';
import 'app_logo.dart';
import 'branded_app_bar_title.dart';
import 'mobile/app_scaffold_mobile.dart';
import 'mobile/app_sheet.dart';

/// Persistent chrome mounted by the router's `StatefulShellRoute` around
/// every authenticated app page — desktop sidebar + top bar, or mobile top
/// bar + bottom nav.
///
/// [navigationShell] both renders the branch stacks (as an `IndexedStack`, so
/// every tab keeps its state and scroll position) and reports which branch is
/// active, so the navigation UI never has to infer the selected tab by
/// string-matching the current path the way it used to.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBreakpoints.isDesktop(context)
        ? _DesktopShell(navigationShell: navigationShell)
        : _MobileShell(navigationShell: navigationShell);
  }
}

/// Switches to the branch at [index], or — when it is already the active one
/// — returns it to its root and scrolls [scrollController] back to the top.
///
/// Re-tapping the selected tab doing nothing is one of those small absences
/// that makes an app feel inert; every phone app treats it as "take me back
/// to the start of this section".
///
/// [scrollController] is the branch's own controller, passed in rather than
/// looked up: the shell installs it *below* itself (see
/// [_MobileShellState._scrollControllers]), so a `PrimaryScrollController.of`
/// from here would search upwards past it and find nothing. Desktop has no
/// per-branch controller and passes null.
void _selectBranch(
  StatefulNavigationShell navigationShell,
  int index, {
  ScrollController? scrollController,
}) {
  // The lightest feedback in the vocabulary: switching tabs is the most
  // frequent gesture in the app, and anything stronger turns routine
  // navigation into a series of thuds.
  AppHaptics.selection();

  final isReselect = index == navigationShell.currentIndex;
  navigationShell.goBranch(index, initialLocation: isReselect);

  if (!isReselect) return;
  if (scrollController == null || !scrollController.hasClients) return;
  scrollController.animateTo(
    0,
    duration: AppMotion.slow,
    curve: AppMotion.enter,
  );
}

// ---------------------------------------------------------------------------
// Desktop
// ---------------------------------------------------------------------------

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final role = ref.watch(sessionControllerProvider).user?.role;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            colorScheme: colorScheme,
            role: role,
            navigationShell: navigationShell,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop sidebar order. A Club's Community entry deliberately sits below
/// Players (the Club Experience 2.0 brief is explicit that Community must not
/// outrank Players in a Club's navigation); everyone else keeps the original
/// order. Add Player and Edit Profile aren't listed — they're already
/// reachable from the screens that own them.
List<AppBranch> _sidebarBranchesFor(UserRole? role) => switch (role) {
  UserRole.club => const [
    AppBranch.home,
    AppBranch.clubProfile,
    AppBranch.clubPlayers,
    AppBranch.search,
    AppBranch.savedPlayers,
    AppBranch.community,
    AppBranch.settings,
  ],
  UserRole.player => const [
    AppBranch.home,
    AppBranch.community,
    AppBranch.playerProfile,
    AppBranch.playerSkills,
    AppBranch.settings,
  ],
  UserRole.admin => const [
    AppBranch.home,
    AppBranch.community,
    AppBranch.adminUsers,
    AppBranch.adminPlayersClubs,
    AppBranch.settings,
  ],
  null => const [AppBranch.home, AppBranch.community, AppBranch.settings],
};

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.colorScheme,
    required this.role,
    required this.navigationShell,
  });

  final ColorScheme colorScheme;
  final UserRole? role;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: AppLogo(height: 32),
          ),
          const Divider(height: 1),
          for (final branch in _sidebarBranchesFor(role))
            ListTile(
              leading: Icon(
                navigationShell.currentIndex == branch.index
                    ? branch.selectedIcon
                    : branch.icon,
              ),
              title: Text(branch.label(l10n)),
              selected: navigationShell.currentIndex == branch.index,
              onTap: () => _selectBranch(navigationShell, branch.index),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      automaticallyImplyLeading: false,
      title: const _UserIdentity(),
      actions: [
        // First in the row: the one action here whose content changes
        // without the user doing anything.
        const NotificationBell(),
        IconButton(
          tooltip: l10n.themeToggleTooltip,
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          icon: Icon(themeModeToggleIcon(themeMode)),
        ),
        const LanguageToggleButton(),
        IconButton(
          tooltip: l10n.logoutTooltip,
          onPressed: () =>
              ref.read(sessionControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
    );
  }
}

/// Small avatar + first name, sourced from the role-appropriate profile when
/// one is available (Player photo/name, Club logo/name); falls back to the
/// account email — and to an initials avatar — when no profile photo exists
/// yet.
class _UserIdentity extends ConsumerWidget {
  const _UserIdentity({this.showName = true, this.radius = 16});

  final bool showName;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final email = user?.email ?? '';

    String? photoUrl;
    String displayName;
    switch (user?.role) {
      case UserRole.player:
        final profile = ref.watch(playerProfileControllerProvider).value;
        photoUrl = profile?.profilePhoto?.secureUrl;
        displayName = (profile?.firstName?.isNotEmpty ?? false)
            ? profile!.firstName!
            : email;
      case UserRole.club:
        final profile = ref.watch(clubProfileControllerProvider).value;
        photoUrl = profile?.logoUrl;
        displayName = (profile?.name?.isNotEmpty ?? false)
            ? profile!.name!
            : email;
      case UserRole.admin:
      case null:
        displayName = email;
    }

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: photoUrl != null
          ? appImageProvider(
              photoUrl,
              context: context,
              decodeWidth: AppImageSize.avatarLarge,
            )
          : null,
      child: photoUrl == null
          ? Text(initial, style: TextStyle(fontSize: radius * 0.9))
          : null,
    );

    if (!showName) return avatar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: AppSpacing.sm + 2),
        Flexible(child: Text(displayName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile
// ---------------------------------------------------------------------------

class _MobileShell extends ConsumerStatefulWidget {
  const _MobileShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<_MobileShell> {
  /// One controller per branch, so "scroll this tab to the top" means *this*
  /// tab and not whichever list happened to attach last. Branch stacks all
  /// stay mounted inside the shell's IndexedStack, so a single shared
  /// controller would end up with several attached positions at once.
  late final List<ScrollController> _scrollControllers = List.generate(
    AppBranch.values.length,
    (_) => ScrollController(),
  );

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openAccountSheet(List<AppBranch> overflow) {
    final l10n = AppLocalizations.of(context)!;
    AppSheet.show<void>(
      context: context,
      builder: (sheetContext) => _AccountSheet(
        branches: overflow,
        l10n: l10n,
        onSelect: (branch) {
          Navigator.of(sheetContext).pop();
          _selectBranch(
            widget.navigationShell,
            branch.index,
            scrollController: _scrollControllers[branch.index],
          );
        },
        onLogout: () {
          Navigator.of(sheetContext).pop();
          ref.read(sessionControllerProvider.notifier).logout();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(sessionControllerProvider).user?.role;
    final tabs = tabBranchesFor(role);
    final overflow = overflowBranchesFor(role);

    final path = GoRouterState.of(context).uri.path;
    final meta = routeMetaFor(path);
    final currentIndex = widget.navigationShell.currentIndex;

    // The account slot counts as selected whenever the active branch is one
    // of the screens that lives behind it — otherwise opening Settings from
    // the sheet would leave Home looking like the current tab.
    final selectedTab = tabs.indexWhere((b) => b.index == currentIndex);
    final isOverflowActive = selectedTab == -1;

    // A migrated screen draws its own collapsing, blurred bar (see
    // AppScaffoldMobile), so the shell stands down and lets its content run
    // edge to edge under the tab bar. Screens that haven't moved over yet
    // keep the fixed bar below.
    final ownsChrome = meta?.ownsChrome ?? false;

    return Scaffold(
      extendBody: ownsChrome,
      appBar: ownsChrome
          ? null
          : _MobileAppBar(
              meta: meta,
              onBack: meta?.parentPath == null
                  ? null
                  : () => context.go(meta!.parentPath!),
            ),
      body: _EdgeSwipeBack(
        onBack: meta?.parentPath == null
            ? null
            : () => context.go(meta!.parentPath!),
        child: PrimaryScrollController(
          controller: _scrollControllers[currentIndex],
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: _MobileTabBar(
        tabs: tabs,
        l10n: l10n,
        translucent: ownsChrome,
        selectedTab: isOverflowActive ? null : selectedTab,
        onSelect: (index) => _selectBranch(
          widget.navigationShell,
          tabs[index].index,
          scrollController: _scrollControllers[tabs[index].index],
        ),
        accountSlot: overflow.isEmpty
            ? null
            : _AccountTabSlot(
                selected: isOverflowActive,
                label: l10n.moreNavLabel,
                onTap: () => _openAccountSheet(overflow),
              ),
      ),
    );
  }
}

/// Swiping in from the leading edge goes back, the way it does in every
/// phone app. [onBack] is the same action the app bar's back button runs;
/// `null` on a screen that has nowhere to go back to, which also removes the
/// gesture entirely rather than leaving a dead zone.
///
/// The detector is a narrow strip rather than the whole screen on purpose: a
/// full-width horizontal drag listener would fight every carousel, slider and
/// swipeable row on the page for the same gesture. Twenty-four logical pixels
/// is what the platforms themselves reserve.
class _EdgeSwipeBack extends StatelessWidget {
  const _EdgeSwipeBack({required this.onBack, required this.child});

  final VoidCallback? onBack;
  final Widget child;

  /// Distance and speed a flick has to clear to count. Low enough to feel
  /// effortless, high enough that a hesitant thumb resting on the edge
  /// doesn't navigate.
  static const _minDistance = 48.0;
  static const _minVelocity = 200.0;

  @override
  Widget build(BuildContext context) {
    if (onBack == null) return child;

    // In RTL the leading edge is the right one, and "back" is a drag towards
    // the left — so both the strip's side and the expected sign flip. Reading
    // them off the same Directionality keeps the gesture and the app bar's
    // mirrored arrow pointing the same way.
    final sign = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    var travelled = 0.0;

    return Stack(
      children: [
        child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: 24,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => travelled = 0,
            onHorizontalDragUpdate: (details) => travelled += details.delta.dx,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (travelled * sign > _minDistance ||
                  velocity * sign > _minVelocity) {
                onBack!();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// The mobile top bar. Unlike the previous one — a fixed logo plus three
/// icon buttons, identical on every screen — this one names the screen you
/// are on and offers a way back out of it. The logo appears only on Home,
/// the way a phone app puts its wordmark on the first tab and a screen name
/// on every other; the theme/language/logout controls moved into the account
/// sheet, where a phone app keeps them.
class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileAppBar({required this.meta, required this.onBack});

  final AppRouteMeta? meta;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = meta?.title;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: onBack == null ? null : 0,
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: l10n.backLabel,
              onPressed: onBack,
              // Mirrors itself in RTL — the one place a back arrow must not
              // be a fixed glyph.
              icon: const Icon(Icons.arrow_back),
            ),
      title: BrandedAppBarTitle(title: title?.call(l10n)),
      actions: const [NotificationBell()],
    );
  }
}

/// The bottom tab bar. Hand-built rather than a `NavigationBar` because the
/// account slot isn't a destination — it opens a sheet — and because the
/// filled/outlined icon swap and the press feedback below are what separate a
/// tab bar that feels like an app from one that feels like a row of links.
class _MobileTabBar extends StatelessWidget {
  const _MobileTabBar({
    required this.tabs,
    required this.l10n,
    required this.translucent,
    required this.selectedTab,
    required this.onSelect,
    required this.accountSlot,
  });

  final List<AppBranch> tabs;
  final AppLocalizations l10n;

  /// Blurs and lets content show through, but only on screens that scroll
  /// their content underneath it. On a screen that stops at the bar, a
  /// translucent bar has nothing to reveal and just looks washed out.
  final bool translucent;

  /// `null` while a screen behind the account slot is showing.
  final int? selectedTab;
  final ValueChanged<int> onSelect;
  final Widget? accountSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bar = SafeArea(
      top: false,
      child: SizedBox(
        height: AppScaffoldMobile.tabBarHeight,
        // The bar is a fixed height, so its labels cannot be. At the system
        // maximum of 2x on a 320px phone this overflowed by 5 pixels —
        // measured, not guessed. Clamping the label is the standard trade
        // both platforms make for a tab bar and the right one here: the icon
        // carries the same meaning at any size, the Semantics label is read
        // aloud at any size, and the alternative is a navigation bar eating a
        // third of a small screen. Only this subtree is clamped; nothing else
        // in the app is.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabSlot(
                    icon: selectedTab == i
                        ? tabs[i].selectedIcon
                        : tabs[i].icon,
                    label: tabs[i].label(l10n),
                    selected: selectedTab == i,
                    onTap: () => onSelect(i),
                  ),
                ),
              if (accountSlot != null) Expanded(child: accountSlot!),
            ],
          ),
        ),
      ),
    );

    // Material either way — the tab slots' ink and the bar's own hairline
    // both need one — but only translucent where content runs underneath.
    return Material(
      color: translucent ? Colors.transparent : theme.colorScheme.surface,
      child: translucent
          ? BlurredSurface(color: theme.colorScheme.surface, child: bar)
          : bar,
    );
  }
}

/// One tab. Scales down slightly while held — the only feedback a flat icon
/// can give that a finger actually landed on it, and its absence is a large
/// part of why a web app feels unresponsive to touch.
class _TabSlot extends StatefulWidget {
  const _TabSlot({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabSlot> createState() => _TabSlotState();
}

class _TabSlotState extends State<_TabSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        // Both animations below collapse to nothing when the platform asks
        // for reduced motion. The press scale and the icon cross-fade were
        // added here without that check; the page transitions had it from
        // the start, and a setting that silences one and not the other is
        // worse than either answer applied consistently.
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: reduceMotion ? Duration.zero : AppMotion.fast,
          curve: AppMotion.enter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : AppMotion.fast,
                child: Icon(
                  widget.icon,
                  key: ValueKey((widget.icon, widget.selected)),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last tab slot: the user's own avatar rather than a "…" glyph, so the
/// account sheet is where you'd expect an account to be.
class _AccountTabSlot extends StatelessWidget {
  const _AccountTabSlot({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              // No badge here. The count used to ride on this avatar, back
              // when the account sheet was the only way to reach
              // Notifications. The header bell is now that affordance, and
              // two badges for one number would have the user checking
              // whichever they noticed first and wondering why the other
              // agreed.
              child: const _UserIdentity(showName: false, radius: 11),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the account slot opens: who you're signed in as, the screens that
/// didn't earn a permanent tab, the app-wide toggles that used to occupy the
/// top bar on every single screen, and a clearly separated way out.
class _AccountSheet extends StatelessWidget {
  const _AccountSheet({
    required this.branches,
    required this.l10n,
    required this.onSelect,
    required this.onLogout,
  });

  final List<AppBranch> branches;
  final AppLocalizations l10n;
  final ValueChanged<AppBranch> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Row(children: [_UserIdentity(radius: 22)]),
          ),
          const Divider(height: 1),
          for (final branch in branches)
            ListTile(
              leading: Icon(branch.icon),
              title: Text(branch.label(l10n)),
              onTap: () => onSelect(branch),
            ),
          const _ThemeAndLanguageRow(),
          const _InstallAppRow(),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.logoutTooltip,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

/// Offers to install the app, but only where that means something.
///
/// Chromium hands over a prompt that installs in one tap. Safari hands over
/// nothing — an iOS install is a manual Share-sheet action — so there the row
/// opens the three steps instead. Everywhere else, and once the app is
/// already installed, the row isn't there at all: a row that does nothing is
/// worse than no row.
class _InstallAppRow extends StatelessWidget {
  const _InstallAppRow();

  @override
  Widget build(BuildContext context) {
    final offer = installOffer();
    if (offer == InstallOffer.none) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.install_mobile_outlined),
      title: Text(l10n.installAppLabel),
      onTap: () {
        // Called straight from the tap, with no await before it: the browser
        // only accepts the prompt from inside a user gesture.
        if (offer == InstallOffer.prompt) {
          promptInstall();
          return;
        }
        AppSheet.show<void>(
          context: context,
          title: l10n.installAppIosTitle,
          builder: (_) => _IosInstallSteps(l10n: l10n),
        );
      },
    );
  }
}

class _IosInstallSteps extends StatelessWidget {
  const _IosInstallSteps({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.ios_share, l10n.installAppIosStep1),
      (Icons.add_box_outlined, l10n.installAppIosStep2),
      (Icons.check_circle_outline, l10n.installAppIosStep3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, text) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeAndLanguageRow extends ConsumerWidget {
  const _ThemeAndLanguageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(themeModeToggleIcon(themeMode)),
      title: Text(l10n.themeToggleTooltip),
      trailing: const LanguageToggleButton(),
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}
