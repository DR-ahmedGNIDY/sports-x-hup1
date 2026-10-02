import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_product.dart';
import '../../store/presentation/widgets/money.dart';
import '../application/admin_store_controllers.dart';
import 'admin_product_image_gallery.dart';
import 'admin_store_page.dart';
import 'admin_store_product_editor.dart';

class AdminStoreProductsTab extends ConsumerStatefulWidget {
  const AdminStoreProductsTab({super.key});

  @override
  ConsumerState<AdminStoreProductsTab> createState() =>
      _AdminStoreProductsTabState();
}

class _AdminStoreProductsTabState extends ConsumerState<AdminStoreProductsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(adminProductsControllerProvider);
    final controller = ref.read(adminProductsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.adminProductSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                  onSubmitted: (value) => controller.search(
                    value.trim().isEmpty ? null : value.trim(),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => showProductEditor(context, ref, null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.adminProductNew),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreProduct>(
            value: products,
            emptyMessage: l10n.adminProductsEmpty,
            onRetry: () => ref.invalidate(adminProductsControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length + (controller.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: controller.loadMore,
                        child: Text(l10n.loadMoreLabel),
                      ),
                    ),
                  );
                }
                return _ProductRow(product: items[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    // Null means the response did not carry the flag, which for an admin
    // response it always does; treating null as listed keeps the row
    // readable rather than mislabelling it.
    final isListed = product.isActive ?? true;
    final totalStock = product.variants.fold<int>(
      0,
      (sum, variant) => sum + (variant.stock ?? 0),
    );

    return ListTile(
      leading: SizedBox(
        width: 44,
        height: 56,
        child: product.imageUrl == null
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: scheme.outline,
                ),
              )
            : Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHighest),
              ),
      ),
      title: Text(product.title.resolve(true)),
      subtitle: Text(
        '${formatMoney(product.priceMinor, isArabic: isArabic)}  ·  '
        '${l10n.adminProductOptionsCount(product.variants.length)}  ·  '
        '${l10n.adminProductInStock(totalStock)}'
        '${isListed ? '' : l10n.adminProductUnlistedSuffix}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.isFeatured)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.star, size: 16),
            ),
          IconButton(
            tooltip: l10n.adminProductImagesTooltip,
            onPressed: () => _manageImages(context, ref),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
          ),
          IconButton(
            tooltip: l10n.editLabel,
            onPressed: () => showProductEditor(context, ref, product),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: isListed
                ? l10n.adminProductUnlistTooltip
                : l10n.adminProductAlreadyUnlisted,
            onPressed: isListed ? () => _confirmUnlist(context, ref) : null,
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlist(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminProductUnlistTitle),
        // Says what actually happens, because "delete" would be a lie: the
        // document survives so past orders still render.
        content: Text(l10n.adminProductUnlistBody(product.title.resolve(true))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adminProductUnlistConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(adminProductsControllerProvider.notifier)
        .deactivate(product.id);
  }

  Future<void> _manageImages(BuildContext context, WidgetRef ref) =>
      showDialog<void>(
        context: context,
        builder: (context) => _ImagesDialog(product: product),
      );
}

/// The gallery, opened from a product's row.
class _ImagesDialog extends StatelessWidget {
  const _ImagesDialog({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.adminProductImagesTitle(product.title.resolve(true))),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: ProductImageGallery(product: product),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminCloseLabel),
        ),
      ],
    );
  }
}
