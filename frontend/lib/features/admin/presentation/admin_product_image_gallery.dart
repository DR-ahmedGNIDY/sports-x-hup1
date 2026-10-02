import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_product.dart';
import '../application/admin_store_controllers.dart';

/// A product's photos: thumbnails, remove, and an upload button. Used inside
/// the product editor and by the gallery dialog on the products list.
///
/// Order matters — the first image is the one every storefront tile shows —
/// and the only control over it is upload order, so that is stated.
class ProductImageGallery extends ConsumerStatefulWidget {
  const ProductImageGallery({super.key, required this.product});

  final StoreProduct product;

  @override
  ConsumerState<ProductImageGallery> createState() =>
      _ProductImageGalleryState();
}

class _ProductImageGalleryState extends ConsumerState<ProductImageGallery> {
  late StoreProduct _product = widget.product;
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.adminProductImagesHint, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _product.images.length; i++)
              _Thumb(
                image: NetworkImage(_product.images[i].url),
                isPrimary: i == 0,
                onRemove: _busy ? null : () => _remove(i),
              ),
            // The upload control sits in the grid, where the next photo will
            // appear, so it reads as "add one here".
            _UploadTile(busy: _busy, onTap: _busy ? null : _pickAndUpload),
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
    required this.image,
    required this.isPrimary,
    required this.onRemove,
  });

  final ImageProvider image;
  final bool isPrimary;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 96,
      height: 128,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          if (isPrimary)
            PositionedDirectional(
              start: 0,
              top: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  l10n.adminProductImageCardBadge,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          PositionedDirectional(
            end: 0,
            top: 0,
            child: IconButton(
              tooltip: l10n.adminProductRemoveImageTooltip,
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

/// Photos chosen for a product that does not exist yet. The API attaches an
/// image to a saved product only, so these wait in memory and the editor
/// uploads them, in this order, right after the product is created.
class PendingImagePicker extends StatelessWidget {
  const PendingImagePicker({
    super.key,
    required this.files,
    required this.onChanged,
    this.enabled = true,
  });

  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onChanged;
  final bool enabled;

  Future<void> _pick() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    final chosen = [
      for (final f in picked?.files ?? const <PlatformFile>[])
        if (f.bytes != null) f,
    ];
    if (chosen.isEmpty) return;
    onChanged([...files, ...chosen]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.adminProductImagesHint, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < files.length; i++)
              _Thumb(
                image: MemoryImage(files[i].bytes!),
                isPrimary: i == 0,
                onRemove: enabled
                    ? () => onChanged([...files]..removeAt(i))
                    : null,
              ),
            _UploadTile(busy: false, onTap: enabled ? _pick : null),
          ],
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 96,
      height: 128,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminUploadLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
