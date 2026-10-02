import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_category.dart';
import '../../store/domain/entities/store_product.dart';
import '../application/admin_store_controllers.dart';
import 'admin_product_image_gallery.dart';
import 'admin_store_categories_tab.dart' show categoryTree;
import 'admin_store_page.dart';

/// Opens the create/edit form. [product] null means "new".
Future<void> showProductEditor(
  BuildContext context,
  WidgetRef ref,
  StoreProduct? product,
) => showDialog<void>(
  context: context,
  builder: (context) => _ProductEditor(product: product),
);

class _ProductEditor extends ConsumerStatefulWidget {
  const _ProductEditor({required this.product});

  final StoreProduct? product;

  @override
  ConsumerState<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<_ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  // The product being edited — null for a new one. Set after creation only
  // when some picked photos failed to upload, so the editor can stay open on
  // the saved product and offer them again.
  late StoreProduct? _product = widget.product;

  // Photos picked before a new product's first save; uploaded by [_save]
  // right after the product is created.
  List<PlatformFile> _pendingImages = const [];

  // Arabic only: the store is Arabic-first. The API still requires English
  // text, so [_save] fills it — see there.
  late final _titleAr = TextEditingController(
    text: widget.product?.title.resolve(true),
  );
  late final _descriptionAr = TextEditingController(
    text: widget.product?.description?.resolve(true),
  );
  late final _price = TextEditingController(
    text: widget.product == null
        ? ''
        : minorToPounds(widget.product!.priceMinor),
  );
  late final _compareAt = TextEditingController(
    text: widget.product?.compareAtPriceMinor == null
        ? ''
        : minorToPounds(widget.product!.compareAtPriceMinor!),
  );

  late String? _categoryId = widget.product?.categoryId;
  late ProductBadge _badge = widget.product?.badge ?? ProductBadge.none;
  late bool _isFeatured = widget.product?.isFeatured ?? false;
  late bool _isActive = widget.product?.isActive ?? true;
  late final List<_VariantDraft> _variants = [
    for (final variant in widget.product?.variants ?? const <ProductVariant>[])
      _VariantDraft(
        size: variant.size ?? '',
        colour: variant.colour ?? '',
        sku: variant.sku ?? '',
        stock: variant.stock ?? 0,
      ),
  ];

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_titleAr, _descriptionAr, _price, _compareAt]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(adminCategoriesControllerProvider);

    return AlertDialog(
      title: Text(
        _product == null ? l10n.adminProductNew : l10n.adminProductEditTitle,
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  l10n,
                  _titleAr,
                  l10n.adminProductNameLabel,
                  required: true,
                ),
                _field(
                  l10n,
                  _descriptionAr,
                  l10n.adminProductDescriptionLabel,
                  maxLines: 3,
                ),
                categories.when(
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: _validCategory(_shelves(items)),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.adminProductCategoryLabel,
                    ),
                    // Shelves only, each named with its department ("رجالي ←
                    // ملابس"): a product is filed on a shelf, and the bare
                    // shelf names repeat across departments.
                    items: [
                      for (final category in _shelves(items))
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            _shelfLabel(category, items) +
                                (category.isActive == false
                                    ? l10n.adminProductCategoryHiddenSuffix
                                    : ''),
                          ),
                        ),
                    ],
                    validator: (value) => value == null
                        ? l10n.adminProductPickCategoryError
                        : null,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) =>
                      Text(l10n.adminProductCategoriesFailed('$error')),
                ),
                const SizedBox(height: 12),
                _Pair(
                  left: _field(
                    l10n,
                    _price,
                    l10n.adminProductPriceEgpLabel,
                    required: true,
                    validator: (value) => _priceValidator(l10n, value),
                  ),
                  // Named for what it does on the card rather than
                  // "compareAtPrice", which means nothing to a merchant.
                  right: _field(
                    l10n,
                    _compareAt,
                    l10n.adminProductWasPriceLabel,
                    validator: (value) => _compareAtValidator(l10n, value),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ProductBadge>(
                        initialValue: _badge,
                        decoration: InputDecoration(
                          labelText: l10n.adminProductBadgeLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: ProductBadge.none,
                            child: Text(l10n.adminProductBadgeNone),
                          ),
                          DropdownMenuItem(
                            value: ProductBadge.isNew,
                            child: Text(l10n.adminProductBadgeNew),
                          ),
                          DropdownMenuItem(
                            value: ProductBadge.preOrder,
                            child: Text(l10n.adminProductBadgePreOrder),
                          ),
                          DropdownMenuItem(
                            value: ProductBadge.sale,
                            child: Text(l10n.adminProductBadgeSale),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _badge = value ?? ProductBadge.none),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(l10n.adminProductFeaturedLabel),
                            subtitle: Text(l10n.adminProductFeaturedHint),
                            value: _isFeatured,
                            onChanged: (value) =>
                                setState(() => _isFeatured = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(l10n.adminProductListedLabel),
                            subtitle: Text(l10n.adminProductListedHint),
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Text(
                      l10n.adminProductOptionsTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    // Stock lives on the option, not the product, because
                    // "Black / L is sold out" is the answer the cart needs.
                    Expanded(
                      child: Text(
                        l10n.adminProductOptionsHint,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _variants.add(_VariantDraft())),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.adminProductAddOption),
                    ),
                  ],
                ),
                for (var i = 0; i < _variants.length; i++)
                  _VariantRow(
                    draft: _variants[i],
                    onRemove: () => setState(() => _variants.removeAt(i)),
                  ),
                const Divider(height: 32),
                Text(
                  l10n.adminProductPhotosTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_product == null)
                  PendingImagePicker(
                    files: _pendingImages,
                    enabled: !_busy,
                    onChanged: (files) =>
                        setState(() => _pendingImages = files),
                  )
                else
                  ProductImageGallery(
                    key: ValueKey(_product!.id),
                    product: _product!,
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveLabel),
        ),
      ],
    );
  }

  /// A product whose category was hidden still names it, but the dropdown
  /// would throw on a value not in its item list — so an unknown id falls
  /// back to unset rather than crashing the editor.
  /// Leaf categories in tree order. A department with no shelves stays
  /// pickable so a store that has not split its departments still works.
  List<StoreCategory> _shelves(List<StoreCategory> items) {
    final parentIds = {for (final c in items) c.parentId}..remove(null);
    return categoryTree(items).where((c) => !parentIds.contains(c.id)).toList();
  }

  String _shelfLabel(StoreCategory category, List<StoreCategory> items) {
    final name = category.name.resolve(true);
    final parent = items.where((c) => c.id == category.parentId).firstOrNull;
    return parent == null ? name : '${parent.name.resolve(true)} ← $name';
  }

  String? _validCategory(List<StoreCategory> items) {
    if (_categoryId == null) return null;
    return items.any((c) => c.id == _categoryId) ? _categoryId : null;
  }

  String? _priceValidator(AppLocalizations l10n, String? value) =>
      poundsToMinor(value ?? '') == null ? l10n.adminProductPriceExample : null;

  String? _compareAtValidator(AppLocalizations l10n, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final was = poundsToMinor(text);
    if (was == null) return l10n.adminProductWasPriceExample;
    final now = poundsToMinor(_price.text);
    // The API refuses this too; catching it here saves a round trip and
    // explains it in the merchant's own terms.
    if (now != null && was <= now) {
      return l10n.adminProductWasPriceHigherError;
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;

    final compareAt = poundsToMinor(_compareAt.text);
    final title = _titleAr.text.trim();
    final description = _descriptionAr.text.trim();
    // The API requires an English title (and English with any description).
    // The admin writes Arabic only, so the Arabic text fills English as
    // well; a product that already had real English text keeps it.
    final keptEnTitle = _product?.title.en;
    final keptEnDescription = _product?.description?.en;
    final body = <String, dynamic>{
      'title': {
        'en': keptEnTitle != null && keptEnTitle != _product?.title.ar
            ? keptEnTitle
            : title,
        'ar': title,
      },
      if (description.isNotEmpty)
        'description': {
          'en':
              keptEnDescription != null &&
                  keptEnDescription != _product?.description?.ar
              ? keptEnDescription
              : description,
          'ar': description,
        },
      'categoryId': categoryId,
      'priceMinor': poundsToMinor(_price.text),
      if (_compareAt.text.trim().isNotEmpty) 'compareAtPriceMinor': compareAt,
      if (_badge != ProductBadge.none) 'badge': _badgeWireValue(_badge),
      'variants': [
        for (final draft in _variants)
          {
            if (draft.size.trim().isNotEmpty) 'size': draft.size.trim(),
            if (draft.colour.trim().isNotEmpty) 'colour': draft.colour.trim(),
            if (draft.sku.trim().isNotEmpty) 'sku': draft.sku.trim(),
            'stock': draft.stock,
          },
      ],
      'isFeatured': _isFeatured,
      'isActive': _isActive,
    };

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(adminProductsControllerProvider.notifier);
      final existing = _product;
      if (existing == null) {
        final created = await controller.create(body);
        var latest = created;
        final failed = <String>[];
        for (final file in _pendingImages) {
          try {
            latest = await controller.addImage(
              created.id,
              file.bytes!,
              file.name,
            );
          } catch (_) {
            failed.add(file.name);
          }
        }
        if (!mounted) return;
        if (failed.isEmpty) {
          Navigator.of(context).pop();
          return;
        }
        // The product exists now; keep the editor open on it, with the
        // uploaded photos in the live gallery, so the rest can be retried.
        setState(() {
          _product = latest;
          _pendingImages = const [];
          _error = AppLocalizations.of(
            context,
          )!.adminProductSomePhotosFailed(failed.join('، '));
        });
        return;
      }
      await controller.save(existing.id, body);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The enum's Dart names differ from the wire values (`isNew` cannot be
  /// called `new`), so the mapping is explicit rather than `.name`.
  String _badgeWireValue(ProductBadge badge) => switch (badge) {
    ProductBadge.isNew => 'new',
    ProductBadge.preOrder => 'pre_order',
    ProductBadge.sale => 'sale',
    ProductBadge.none => '',
  };

  Widget _field(
    AppLocalizations l10n,
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, isDense: true),
      validator:
          validator ??
          (required
              ? (value) => (value ?? '').trim().isEmpty
                    ? l10n.storeRequiredField
                    : null
              : null),
    ),
  );
}

class _VariantDraft {
  _VariantDraft({
    this.size = '',
    this.colour = '',
    this.sku = '',
    this.stock = 0,
  });

  String size;
  String colour;
  String sku;
  int stock;
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.draft, required this.onRemove});

  final _VariantDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: draft.size,
              decoration: InputDecoration(
                labelText: l10n.adminProductSizeLabel,
                isDense: true,
              ),
              onChanged: (value) => draft.size = value,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: draft.colour,
              decoration: InputDecoration(
                labelText: l10n.adminProductColourLabel,
                isDense: true,
              ),
              onChanged: (value) => draft.colour = value,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: draft.sku,
              decoration: InputDecoration(
                labelText: l10n.adminProductSkuLabel,
                isDense: true,
              ),
              onChanged: (value) => draft.sku = value,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextFormField(
              initialValue: '${draft.stock}',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.adminProductStockLabel,
                isDense: true,
              ),
              validator: (value) =>
                  int.tryParse((value ?? '').trim()) == null ? '?' : null,
              onChanged: (value) =>
                  draft.stock = int.tryParse(value.trim()) ?? 0,
            ),
          ),
          IconButton(
            tooltip: l10n.adminProductRemoveOptionTooltip,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 16),
      Expanded(child: right),
    ],
  );
}
