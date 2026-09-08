import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/store_theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/catalog_providers.dart';
import '../domain/entities/store_category.dart';
import 'widgets/product_carousel.dart';
import 'widgets/store_scaffold.dart';
import 'store_paths.dart';

/// The storefront home page.
///
/// Structure taken from the reference site: a full-bleed image with no
/// overlay text at all, a floating call to action that follows the scroll,
/// then a stack of product rows. The hero carries no copy on purpose — a
/// headline over a photograph of a garment competes with the garment.
class StoreHomePage extends ConsumerWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(storeCategoriesProvider);
    final featured = ref.watch(
      productListProvider(const ProductQuery(featured: true)),
    );
    final newest = ref.watch(productListProvider(const ProductQuery()));

    return StoreScaffold(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const _Hero(),
              newest.when(
                data: (page) => ProductCarousel(
                  title: l10n.storeNewArrivals,
                  products: page.items,
                  onProductTap: (product) =>
                      context.go(StorePaths.product(product.slug)),
                  onViewAll: () => context.go(StorePaths.shop),
                ),
                loading: () => const _SectionLoading(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              categories.maybeWhen(
                data: (items) => _CategoryStrip(categories: items),
                orElse: () => const SizedBox.shrink(),
              ),
              featured.when(
                data: (page) => ProductCarousel(
                  title: l10n.storeFeatured,
                  products: page.items,
                  onProductTap: (product) =>
                      context.go(StorePaths.product(product.slug)),
                ),
                loading: () => const _SectionLoading(),
                // A failed featured row is not worth an error state on the
                // home page — the rest of the storefront still works.
                error: (_, _) => const SizedBox.shrink(),
              ),
              const StoreFooter(),
            ],
          ),
          // The reference site's one piece of persistent chrome: a dark pill
          // pinned bottom-end that stays put through the whole scroll.
          PositionedDirectional(
            bottom: 20,
            end: 16,
            child: FloatingActionButton.extended(
              onPressed: () => context.go(StorePaths.shop),
              backgroundColor: StoreTheme.ink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.storeShopBestSellers),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    return SizedBox(
      height: isDesktop ? 560 : 460,
      width: double.infinity,
      child: ColoredBox(
        color: Theme.of(context).brightness == Brightness.light
            ? StoreTheme.surfaceAlt
            : StoreTheme.darkSurfaceAlt,
        // Intentionally an empty band until the merchant uploads a banner.
        // A placeholder headline here would have to be written, translated
        // and then deleted — an empty hero is honest about being unset.
        child: const SizedBox.shrink(),
      ),
    );
  }
}

/// "Shop by category" — image tiles, one per top-level category.
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});

  final List<StoreCategory> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final top = categories.where((item) => item.parentId == null).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 48),
        Text(
          l10n.storeShopByCategory,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            itemCount: top.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = top[index];
              return InkWell(
                onTap: () => context.go(StorePaths.category(category.slug)),
                child: SizedBox(
                  width: 150,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppRadius.xxs),
                          ),
                          child: category.imageUrl == null
                              ? ColoredBox(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? StoreTheme.surfaceAlt
                                      : StoreTheme.darkSurfaceAlt,
                                  child: const SizedBox.expand(),
                                )
                              : CachedNetworkImage(
                                  imageUrl: category.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name.resolve(isArabic),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 64),
    child: Center(child: CircularProgressIndicator()),
  );
}
