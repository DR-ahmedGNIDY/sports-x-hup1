import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/store_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/catalog_providers.dart';
import '../domain/entities/store_category.dart';
import 'widgets/product_carousel.dart';
import 'widgets/store_hero.dart';
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
              const StoreHero(),
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
          // Two layouts, chosen by whether the tiles actually fit.
          //
          // A shop with three departments is the normal case here, and a
          // scrolling strip serves it badly: the tiles bunch against the
          // leading edge, the last one is clipped by a hair, and the rest of
          // the row is empty — it reads as broken rather than as scrollable.
          // So when they fit, they share the width instead. A catalogue that
          // grows past what the row can hold falls back to the strip, which
          // is the right answer *then* because there is genuinely more to
          // see than fits.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final needed =
                  top.length * _tileWidth + (top.length - 1) * _tileGap;
              if (needed > constraints.maxWidth - _stripPadding * 2) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: _stripPadding,
                  ),
                  itemCount: top.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _tileGap),
                  itemBuilder: (context, index) => SizedBox(
                    width: _tileWidth,
                    child: _CategoryTile(
                      category: top[index],
                      isArabic: isArabic,
                    ),
                  ),
                );
              }

              // Share the width, but only up to a point. Left to stretch, a
              // three-department shop on a desktop gives each tile a third
              // of the page — 300-odd pixels wide against a 200-tall strip,
              // which turns a portrait card into a letterbox. Past the cap
              // the row centres instead, which is where the eye expects a
              // short row of tiles anyway.
              final each =
                  ((constraints.maxWidth -
                              _stripPadding * 2 -
                              _tileGap * (top.length - 1)) /
                          top.length)
                      .clamp(0.0, _tileMaxWidth);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: _stripPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (index, category) in top.indexed) ...[
                      if (index > 0) const SizedBox(width: _tileGap),
                      SizedBox(
                        width: each,
                        child: _CategoryTile(
                          category: category,
                          isArabic: isArabic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The width one tile prefers in the scrolling layout, and the threshold the
/// flat layout is chosen against.
const double _tileWidth = 150;

/// How wide a tile may grow when it shares the row. Roughly the height of
/// the image area, so the card stays square-ish rather than becoming a
/// letterbox on a wide screen.
const double _tileMaxWidth = 180;

const double _tileGap = 12;
const double _stripPadding = 16;

/// One department: its image over its name. Sized by whatever lays it out —
/// a fixed width in the scrolling strip, an equal share in the flat row.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.isArabic});

  final StoreCategory category;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(StorePaths.category(category.slug)),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.xxs),
              ),
              child: category.imageUrl == null
                  ? ColoredBox(
                      color: Theme.of(context).brightness == Brightness.light
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
