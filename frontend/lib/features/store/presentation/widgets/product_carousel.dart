import 'package:flutter/material.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/store_product.dart';
import 'product_card.dart';

/// A home-page section: centred heading, a horizontal row of products, and a
/// "View all" beneath.
///
/// A row rather than a grid, because that is what the reference storefront
/// does on the home page and it is the better shape for the job — the home
/// page's role is to sample each collection, not to exhaust it. The grid
/// belongs on the listing page, where exhausting it is the point.
class ProductCarousel extends StatelessWidget {
  const ProductCarousel({
    super.key,
    required this.title,
    required this.products,
    required this.onProductTap,
    this.onViewAll,
  });

  final String title;
  final List<StoreProduct> products;
  final void Function(StoreProduct product) onProductTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isDesktop = AppBreakpoints.isDesktop(context);
    // Sized so the next tile is partly visible — a row that ends flush at
    // the edge reads as the end of the list rather than as scrollable.
    final itemWidth = isDesktop ? 260.0 : 168.0;

    return Column(
      children: [
        const SizedBox(height: 48),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          // The tile is 3:4 plus room for two lines of name and the price.
          height: itemWidth * 4 / 3 + 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: itemWidth,
                child: ProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                ),
              );
            },
          ),
        ),
        if (onViewAll != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onViewAll,
            child: Text(l10n.storeViewAll),
          ),
        ],
      ],
    );
  }
}
