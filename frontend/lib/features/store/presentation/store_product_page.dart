import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/store_theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/cart_controller.dart';
import '../application/catalog_providers.dart';
import '../domain/entities/store_product.dart';
import 'widgets/money.dart';
import 'widgets/store_scaffold.dart';

class StoreProductPage extends ConsumerStatefulWidget {
  const StoreProductPage({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<StoreProductPage> createState() => _StoreProductPageState();
}

class _StoreProductPageState extends ConsumerState<StoreProductPage> {
  ProductVariant? _selected;
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = ref.watch(productBySlugProvider(widget.slug));

    return StoreScaffold(
      child: product.when(
        data: (item) => _Body(
          product: item,
          selected: _selected,
          imageIndex: _imageIndex,
          onImage: (index) => setState(() => _imageIndex = index),
          onVariant: (variant) => setState(() => _selected = variant),
          onAdd: () => _add(item),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.genericErrorMessage)),
      ),
    );
  }

  Future<void> _add(StoreProduct product) async {
    final l10n = AppLocalizations.of(context)!;
    final variant = _selected;
    // A product with exactly one variant needs no choice made; anything
    // more and the customer has to pick, or the cart line is ambiguous.
    final chosen = variant ??
        (product.variants.length == 1 ? product.variants.first : null);

    if (chosen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storeSelectSize)),
      );
      return;
    }

    await ref.read(cartControllerProvider.notifier).add(product, chosen);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.storeAddedToBag)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.product,
    required this.selected,
    required this.imageIndex,
    required this.onImage,
    required this.onVariant,
    required this.onAdd,
  });

  final StoreProduct product;
  final ProductVariant? selected;
  final int imageIndex;
  final void Function(int index) onImage;
  final void Function(ProductVariant variant) onVariant;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final gallery = _Gallery(
      product: product,
      index: imageIndex,
      onSelect: onImage,
    );
    final details = _Details(
      product: product,
      selected: selected,
      onVariant: onVariant,
      onAdd: onAdd,
    );

    if (!isDesktop) {
      return ListView(
        children: [gallery, details, const StoreFooter()],
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: gallery),
              const SizedBox(width: 48),
              Expanded(child: details),
            ],
          ),
        ),
        const StoreFooter(),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.product,
    required this.index,
    required this.onSelect,
  });

  final StoreProduct product;
  final int index;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final images = product.images.isEmpty
        ? [?product.imageUrl]
        : product.images.map((image) => image.url).toList();
    final placeholder = ColoredBox(
      color: Theme.of(context).brightness == Brightness.light
          ? StoreTheme.surfaceAlt
          : StoreTheme.darkSurfaceAlt,
      child: const SizedBox.expand(),
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: images.isEmpty
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: images[index.clamp(0, images.length - 1)],
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  width: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: i == index
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.outline,
                      width: i == index ? 1.6 : 1,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => placeholder,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.product,
    required this.selected,
    required this.onVariant,
    required this.onAdd,
  });

  final StoreProduct product;
  final ProductVariant? selected;
  final void Function(ProductVariant variant) onVariant;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title.resolve(isArabic),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          MoneyText(
            priceMinor: product.priceMinor,
            compareAtPriceMinor: product.compareAtPriceMinor,
            align: TextAlign.start,
            fontSize: 18,
          ),
          if (product.variants.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.storeSelectOption,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final variant in product.variants)
                  _VariantChip(
                    variant: variant,
                    isSelected: selected?.id == variant.id,
                    onTap: variant.inStock ? () => onVariant(variant) : null,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              // Disabled outright when nothing is buyable, rather than
              // failing at checkout with the stock error.
              onPressed: product.inStock ? onAdd : null,
              child: Text(
                product.inStock ? l10n.storeAddToBag : l10n.storeSoldOut,
              ),
            ),
          ),
          if (product.description != null) ...[
            const SizedBox(height: 32),
            Text(
              product.description!.resolve(isArabic),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  final ProductVariant variant;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? scheme.onSurface : scheme.outline,
            width: isSelected ? 1.6 : 1,
          ),
          color: isSelected ? scheme.onSurface : null,
        ),
        child: Text(
          variant.label(),
          style: TextStyle(
            color: isDisabled
                ? scheme.outline
                : isSelected
                ? scheme.surface
                : scheme.onSurface,
            // A sold-out option stays visible and struck through rather than
            // disappearing — its absence would read as a size never made.
            decoration: isDisabled ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
