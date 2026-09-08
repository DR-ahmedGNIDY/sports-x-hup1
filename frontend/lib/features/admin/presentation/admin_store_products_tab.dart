import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/store_product.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';
import 'admin_store_product_editor.dart';

class AdminStoreProductsTab extends ConsumerStatefulWidget {
  const AdminStoreProductsTab({super.key});

  @override
  ConsumerState<AdminStoreProductsTab> createState() =>
      _AdminStoreProductsTabState();
}

class _AdminStoreProductsTabState
    extends ConsumerState<AdminStoreProductsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search products',
                    prefixIcon: Icon(Icons.search, size: 18),
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
                label: const Text('New product'),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreProduct>(
            value: products,
            emptyMessage: 'No products yet.',
            onRetry: () =>
                ref.invalidate(adminProductsControllerProvider),
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
                        child: const Text('Load more'),
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
                child: Icon(Icons.image_outlined, size: 18, color: scheme.outline),
              )
            : Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHighest),
              ),
      ),
      title: Text(product.title.en),
      subtitle: Text(
        '${minorToPounds(product.priceMinor)} EGP  ·  '
        '${product.variants.length} options  ·  $totalStock in stock'
        '${isListed ? '' : '  ·  Unlisted'}',
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
            tooltip: 'Images',
            onPressed: () => _manageImages(context, ref),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => showProductEditor(context, ref, product),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: isListed ? 'Unlist' : 'Already unlisted',
            onPressed: isListed ? () => _confirmUnlist(context, ref) : null,
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlist(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlist product?'),
        // Says what actually happens, because "delete" would be a lie: the
        // document survives so past orders still render.
        content: Text(
          '${product.title.en} will stop appearing in the store. Orders that '
          'already include it are unaffected, and you can re-list it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unlist'),
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

/// The gallery editor. Order matters — the first image is the one every
/// storefront tile shows — and the only control over it is upload order, so
/// that is stated rather than left to be discovered.
class _ImagesDialog extends ConsumerStatefulWidget {
  const _ImagesDialog({required this.product});

  final StoreProduct product;

  @override
  ConsumerState<_ImagesDialog> createState() => _ImagesDialogState();
}

class _ImagesDialogState extends ConsumerState<_ImagesDialog> {
  late StoreProduct _product = widget.product;
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Images — ${_product.title.en}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The first image is the one shown on product cards.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_product.images.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No images yet.'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _product.images.length; i++)
                    _Thumb(
                      url: _product.images[i].url,
                      isPrimary: i == 0,
                      onRemove: _busy ? null : () => _remove(i),
                    ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _pickAndUpload,
          icon: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload, size: 18),
          label: const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      // The bytes are what the multipart request needs, and on web there is
      // no path to read from anyway.
      withData: true,
    );
    final file = picked?.files.singleOrNull;
    final bytes = file?.bytes;
    if (bytes == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(adminProductsControllerProvider.notifier)
          .addImage(_product.id, bytes, file!.name);
      if (mounted) setState(() => _product = updated);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int index) async {
    // The API addresses an image by its Cloudinary publicId, which the admin
    // response carries alongside the URL.
    final publicId = _product.images[index].publicId;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(adminProductsControllerProvider.notifier)
          .removeImage(_product.id, publicId);
      if (mounted) setState(() => _product = updated);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.url,
    required this.isPrimary,
    required this.onRemove,
  });

  final String url;
  final bool isPrimary;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 128,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          if (isPrimary)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: const Text(
                  'Card',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              tooltip: 'Remove image',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
