import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notifications/presentation/shared/notification_bell.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../navigation/app_branches.dart';
import '../../theme/app_blur.dart';
import '../../theme/app_spacing.dart';
import '../branded_app_bar_title.dart';

/// The page scaffold for a migrated mobile screen: a collapsing app bar the
/// content scrolls *under*, rather than the fixed opaque bar the shell hands
/// to screens that haven't moved over yet.
///
/// This is what M2 could not do from the shell. A large title has to shrink in
/// step with the page's own scroll offset, which means the bar must be a
/// sliver inside the page's scroll view; and a blurred bar only means anything
/// if content actually passes underneath it. Both need the page's cooperation,
/// so both live here.
///
/// A screen opts in by using this widget *and* setting
/// [AppRouteMeta.ownsChrome], which tells the shell to stand down — otherwise
/// there would be two app bars. The two are checked against each other by
/// test, since getting one without the other is silent rather than loud.
///
/// Title, back button and back destination all come from [routeMetaFor], the
/// same declaration the shell reads, so a screen never states its own name
/// twice.
class AppScaffoldMobile extends StatelessWidget {
  const AppScaffoldMobile({
    super.key,
    required this.slivers,
    this.actions,
    this.onRefresh,
    this.background,
  });

  /// Overrides the page's background, and with it the tint of the blurred
  /// bar. The Player Profile family runs on its own darker palette
  /// (`ProfileColors`), and a bar tinted with the app-wide surface over that
  /// background reads as a seam rather than as the same sheet.
  final Color? background;

  /// The page's content. Plain (non-sliver) content goes in a
  /// `SliverToBoxAdapter`; a list should stay a real sliver so it builds
  /// lazily.
  final List<Widget> slivers;

  /// Trailing app-bar actions. Rare — most screen actions belong in the
  /// content, where they can carry a label.
  ///
  /// The notification bell is appended to whatever a screen passes, so it
  /// appears on every migrated screen without each one remembering to add
  /// it. Screens that want no bell at all are not a case that exists: it is
  /// the one control whose content changes without the user acting, so
  /// hiding it on some screens would mean the app is quietly holding news
  /// wherever you happen to be standing.
  final List<Widget>? actions;

  /// Pull-to-refresh. Omitted when a screen has nothing to refetch.
  final Future<void> Function()? onRefresh;

  /// Height the bottom tab bar occupies, which content must clear when it is
  /// scrolling underneath. Kept here rather than imported from the shell so
  /// this widget stays usable on its own; the shell's test pins them equal.
  static const double tabBarHeight = 60;

  /// Expanded height of a large-title bar: a standard toolbar plus room for
  /// the title to sit below it.
  static const double _expandedHeight = kToolbarHeight + 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final meta = routeMetaFor(GoRouterState.of(context).uri.path);

    final title = meta?.title?.call(l10n);
    final parentPath = meta?.parentPath;

    // A detail screen gets a small title beside its back button; a branch
    // root gets the large one. That split isn't cosmetic — a large title
    // wants the leading edge to itself, and a screen you can go back from
    // has a button sitting exactly there.
    final isDetail = parentPath != null;

    final content = CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: (isDetail || title == null) ? null : _expandedHeight,
          // Transparent so the blur behind it is what you see. Both tints
          // must go: Material 3 otherwise paints a scroll-dependent overlay
          // on top of the blur.
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading: isDetail
              ? IconButton(
                  tooltip: l10n.backLabel,
                  onPressed: () => context.go(parentPath),
                  // Mirrors itself in RTL, unlike a fixed arrow glyph.
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          actions: [...?actions, const NotificationBell()],
          // The wordmark rides in the pinned bar on every screen, not just
          // Home. On a branch root that slot was empty — the section name
          // lives in the collapsing `flexibleSpace` below — so the logo
          // costs nothing there and stops the bar reading as blank. On a
          // detail screen it shares the row with the screen name, which
          // ellipsizes rather than pushing the logo out.
          title: BrandedAppBarTitle(title: isDetail ? title : null),
          flexibleSpace: _BlurredBarBackground(
            color: background,
            child: isDetail || title == null
                ? null
                : FlexibleSpaceBar(
                    // Flush to the leading edge: with no back button there is
                    // nothing for the title to clear.
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    expandedTitleScale: 1.7,
                    title: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ),
        ...slivers,
        // Content scrolls under a translucent tab bar, so the last item needs
        // room to clear it — otherwise the bar is pretty and the final row is
        // unreachable.
        SliverToBoxAdapter(
          child: SizedBox(
            height: tabBarHeight + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );

    final painted = background == null
        ? content
        : ColoredBox(color: background!, child: content);

    if (onRefresh == null) return painted;
    return RefreshIndicator(onRefresh: onRefresh!, child: painted);
  }
}

/// The blurred pane behind the app bar. Separate widget so [child] — the
/// collapsing title, when there is one — paints *above* the blur rather than
/// being blurred along with the content underneath.
class _BlurredBarBackground extends StatelessWidget {
  const _BlurredBarBackground({this.child, this.color});

  final Widget? child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return BlurredSurface(
      color: color ?? Theme.of(context).colorScheme.surface,
      child: child ?? const SizedBox.expand(),
    );
  }
}
