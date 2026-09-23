import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_category.dart';
import '../../store/domain/entities/store_product.dart';
import '../application/admin_store_controllers.dart';
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
  late final _titleEn = TextEditingController(text: widget.product?.title.en);
  late final _titleAr = TextEditingController(text: widget.product?.title.ar);
  late final _descriptionEn = TextEditingController(
    text: widget.product?.description?.en,
  );
  late final _descriptionAr = TextEditingController(
    text: widget.product?.description?.ar,
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
    for (final c in [
      _titleEn,
      _titleAr,
      _descriptionEn,
      _descriptionAr,
      _price,
      _compareAt,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(adminCategoriesControllerProvider);

    return AlertDialog(
      title: Text(widget.product == null ? l10n.adminProductNew : l10n.adminProductEditTitle),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Pair(
                  left: _field(l10n, _titleEn, l10n.adminProductTitleEn, required: true),
                  right: _field(l10n, _titleAr, l10n.adminProductTitleAr),
                ),
                _Pair(
                  left: _field(
                    l10n,
                    _descriptionEn,
                    l10n.adminDescriptionEn,
                    maxLines: 3,
                  ),
                  right: _field(
                    l10n,
                    _descriptionAr,
                    l10n.adminDescriptionAr,
                    maxLines: 3,
                  ),
                ),
                categories.when(
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: _validCategory(items),
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.adminProductCategoryLabel),
                    items: [
                      for (final category in items)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.name.en +
                                (category.isActive == false
                                    ? l10n.adminProductCategoryHiddenSuffix
                                    : ''),
                          ),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.adminProductPickCategoryError : null,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(l10n.adminProductCategoriesFailed('$error')),
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
                        decoration: InputDecoration(labelText: l10n.adminProductBadgeLabel),
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
    final body = <String, dynamic>{
      'title': {
        'en': _titleEn.text.trim(),
        if (_titleAr.text.trim().isNotEmpty) 'ar': _titleAr.text.trim(),
      },
      if (_descriptionEn.text.trim().isNotEmpty)
        'description': {
          'en': _descriptionEn.text.trim(),
          if (_descriptionAr.text.trim().isNotEmpty)
            'ar': _descriptionAr.text.trim(),
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
      if (widget.product == null) {
        await controller.create(body);
      } else {
        await controller.save(widget.product!.id, body);
      }
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
              ? (value) =>
                    (value ?? '').trim().isEmpty ? l10n.storeRequiredField : null
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
              decoration: InputDecoration(labelText: l10n.adminProductSizeLabel, isDense: true),
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
              decoration: InputDecoration(labelText: l10n.adminProductSkuLabel, isDense: true),
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
