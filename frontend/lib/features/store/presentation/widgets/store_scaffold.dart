import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/locale/language_toggle_button.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/cart_controller.dart';
import '../../application/catalog_providers.dart';
import '../store_paths.dart';

/// Every storefront page sits in this: a thin header, the page, and — on a
/// phone — the bottom bar the reference site uses. The footer travels with
/// the scrolling content rather than being pinned here, so a short page does
/// not push it up into view.
class StoreScaffold extends ConsumerWidget {
  const StoreScaffold({
    super.key,
    required this.child,
    this.showBottomBar = true,
  });

  final Widget child;
  final bool showBottomBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = AppBreakpoints.isDesktop(context);

    return Scaffold(
      appBar: const _StoreHeader(),
      body: child,
      bottomNavigationBar: isDesktop || !showBottomBar
          ? null
          : const _StoreBottomBar(),
    );
  }
}

class _StoreHeader extends ConsumerWidget implements PreferredSizeWidget {
  const _StoreHeader();

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final categories = ref.watch(storeCategoriesProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cartCount = ref.watch(cartCountProvider);

    return AppBar(
      // A single hairline under the bar, no elevation and no scroll tint —
      // see StoreTheme for why.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Theme.of(context).colorScheme.outline),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          InkWell(
            onTap: () => context.go(StorePaths.home),
            child: Image.asset(
              'assets/images/logo.png',
              height: 26,
              // The logo is the only branded element in the header; if the
              // asset is missing the header must still be usable.
              errorBuilder: (_, _, _) => const SizedBox(width: 26, height: 26),
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 32),
            // Small, wide-tracked, and quiet — the nav is wayfinding, not a
            // feature list.
            Expanded(
              child: categories.maybeWhen(
                data: (items) => Row(
                  children: [
                    for (final category in items.where(
                      (item) => item.parentId == null,
                    ))
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        child: InkWell(
                          onTap: () => context.go(StorePaths.category(category.slug)),
                          child: Text(
                            category.name.resolve(isArabic),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.storeNavSearch,
          onPressed: () => context.go(StorePaths.search),
          icon: const Icon(Icons.search, size: 22),
        ),
        const LanguageToggleButton(),
        _CartButton(count: cartCount),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.storeNavCart,
          onPressed: () => context.go(StorePaths.cart),
          icon: const Icon(Icons.shopping_bag_outlined, size: 22),
        ),
        if (count > 0)
          PositionedDirectional(
            top: 6,
            end: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: StoreTheme.sale,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The phone-only bottom bar. Lifted from the reference storefront, which
/// uses it to make the site feel like an app — an easy win here, since this
/// one already is one.
class _StoreBottomBar extends ConsumerWidget {
  const _StoreBottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.path;
    final cartCount = ref.watch(cartCountProvider);

    const destinations = ['/', '/cart', '/search', '/orders'];
    final selected = destinations.indexWhere(
      (path) => path == '/' ? location == '/' : location.startsWith(path),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: Theme.of(context).colorScheme.outline),
        NavigationBar(
          height: 62,
          // `indexWhere` yields -1 on a page that is not a destination (a
          // product page, say); NavigationBar rejects that.
          selectedIndex: selected < 0 ? 0 : selected,
          onDestinationSelected: (index) => context.go(destinations[index]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined, size: 20),
              label: l10n.storeNavShop,
            ),
            NavigationDestination(
              icon: Badge.count(
                count: cartCount,
                isLabelVisible: cartCount > 0,
                backgroundColor: StoreTheme.sale,
                child: const Icon(Icons.shopping_bag_outlined, size: 20),
              ),
              label: l10n.storeNavCart,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search, size: 20),
              label: l10n.storeNavSearch,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              label: l10n.storeNavOrders,
            ),
          ],
        ),
      ],
    );
  }
}

/// The trust strip and links at the foot of the scrolling content.
class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      color: isLight ? StoreTheme.surfaceAlt : StoreTheme.darkSurfaceAlt,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 32,
            runSpacing: 20,
            children: [
              _TrustBadge(
                icon: Icons.local_shipping_outlined,
                label: l10n.storeFreeShipping,
              ),
              _TrustBadge(
                icon: Icons.support_agent_outlined,
                label: l10n.storeSupport,
              ),
              _TrustBadge(
                icon: Icons.refresh,
                label: l10n.storeReturns,
              ),
              _TrustBadge(
                icon: Icons.lock_outline,
                label: l10n.storeSecurePayment,
              ),
            ],
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => context.go(StorePaths.track),
            child: Text(l10n.storeTrackOrder),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
