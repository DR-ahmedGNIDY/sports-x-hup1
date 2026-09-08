import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/store_product.dart';
import 'money.dart';

/// A product tile.
///
/// No card, no border, no fill, no shadow — the photograph is the tile, and
/// the name and price sit under it centred. That is what the reference
/// storefront does, and it is why a page of twelve products reads as a
/// catalogue rather than as twelve widgets.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            // Portrait, because clothing is photographed on a standing
            // figure — a square crop cuts the garment.
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Image(url: product.imageUrl),
                if (product.badge != ProductBadge.none)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: _Badge(badge: product.badge),
                  ),
                if (!product.inStock)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.storeSoldOut,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.title.resolve(isArabic),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          MoneyText(
            priceMinor: product.priceMinor,
            compareAtPriceMinor: product.compareAtPriceMinor,
          ),
        ],
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).brightness == Brightness.light
          ? StoreTheme.surfaceAlt
          : StoreTheme.darkSurfaceAlt,
    );
    final source = url;
    if (source == null) return placeholder;

    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.cover,
      // A tile that fails to load must not collapse the grid row — both
      // states fill the same box the image would have.
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});

  final ProductBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, colour) = switch (badge) {
      ProductBadge.isNew => (l10n.storeBadgeNew, StoreTheme.badgeNew),
      ProductBadge.preOrder => (l10n.storeBadgePreOrder, StoreTheme.sale),
      ProductBadge.sale => (l10n.storeBadgeSale, StoreTheme.sale),
      ProductBadge.none => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxs)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
