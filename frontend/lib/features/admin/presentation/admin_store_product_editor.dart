import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_category.dart';
import '../../store/domain/entities/store_product.dart';
import '../application/admin_store_controllers.dart';
import 'admin_product_options.dart';
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

  // Photos already on the product, kept here so a removal shows at once.
  late List<ProductImage> _liveImages = [...?widget.product?.images];

  // Photos picked in this session, by colour name (null: general photos).
  // The API takes images for a saved product, and only for colours it
  // already has, so these all upload in [_save], after the product is.
  final Map<String?, List<PlatformFile>> _pending = {};

  // Colours, sizes and the stock of every colour × size combination. These
  // replace hand-typed option rows: the variants sent to the API are
  // generated from them in [_variantsBody].
  late List<ProductColour> _colours = _initialColours();
  late List<String> _sizes = {
    for (final v in widget.product?.variants ?? const <ProductVariant>[])
      if ((v.size ?? '').isNotEmpty) v.size!,
  }.toList();
  late final Map<String, TextEditingController> _stock = {
    for (final v in widget.product?.variants ?? const <ProductVariant>[])
      _key(v.colour, v.size): TextEditingController(text: '${v.stock ?? 0}'),
  };
  // Kept so an existing variant's SKU survives a save; the form has no SKU
  // field any more.
  late final Map<String, String> _skus = {
    for (final v in widget.product?.variants ?? const <ProductVariant>[])
      if ((v.sku ?? '').isNotEmpty) _key(v.colour, v.size): v.sku!,
  };

  static String _key(String? colour, String? size) =>
      '${colour ?? ''}|${size ?? ''}';

  /// The product's colours; for a product saved before colours had their
  /// own field, rebuilt from the colour names on its variants.
  List<ProductColour> _initialColours() {
    final product = widget.product;
    if (product == null) return [];
    if (product.colours.isNotEmpty) return [...product.colours];
    final names = {
      for (final v in product.variants)
        if ((v.colour ?? '').isNotEmpty) v.colour!,
    };
    return [
      for (final name in names)
        productColourPresets.firstWhere(
          (c) => c.name == name,
          orElse: () => ProductColour(name: name, hex: '#9e9e9e'),
        ),
    ];
  }

  TextEditingController _stockFor(String? colour, String? size) => _stock
      .putIfAbsent(_key(colour, size), () => TextEditingController(text: '0'));

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

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _titleAr,
      _descriptionAr,
      _price,
      _compareAt,
      ..._stock.values,
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
                _sectionTitle(l10n.adminColoursTitle, l10n.adminColoursHint),
                for (final colour in _colours) _colourBlock(l10n, colour),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _busy || _colours.length >= 12
                        ? null
                        : _addColour,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.adminColourAdd),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionTitle(
                  _colours.isEmpty
                      ? l10n.adminProductPhotosTitle
                      : l10n.adminGeneralPhotosTitle,
                  _colours.isEmpty
                      ? l10n.adminProductImagesHint
                      : l10n.adminGeneralPhotosHint,
                ),
                _photoStrip(null),
                const Divider(height: 32),
                _sectionTitle(l10n.adminSizesTitle, l10n.adminSizesHint),
                SizesInput(
                  sizes: _sizes,
                  onChanged: (sizes) => setState(() => _sizes = sizes),
                ),
                const Divider(height: 32),
                _sectionTitle(l10n.adminStockTitle, l10n.adminStockHint),
                _stockGrid(l10n),
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

  Widget _sectionTitle(String title, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(hint, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );

  Widget _colourBlock(AppLocalizations l10n, ProductColour colour) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ColourDot(hex: colour.hex),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                colour.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: l10n.adminColourRemove,
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _colours = _colours.where((c) => c != colour).toList();
                      _pending.remove(colour.name);
                    }),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ],
        ),
        _photoStrip(colour.name),
      ],
    ),
  );

  Widget _photoStrip(String? colour) {
    final names = {for (final c in _colours) c.name};
    return ProductPhotoStrip(
      // General photos include any whose colour is no longer on the form,
      // which is what the API turns them into on save.
      live: _liveImages
          .where(
            (i) => colour == null
                ? i.colour == null || !names.contains(i.colour)
                : i.colour == colour,
          )
          .toList(),
      pending: _pending[colour] ?? const [],
      enabled: !_busy,
      onPendingChanged: (files) => setState(() => _pending[colour] = files),
      onRemoveLive: _removeLiveImage,
    );
  }

  Future<void> _addColour() async {
    final picked = await pickProductColour(context, [
      for (final c in _colours) c.name,
    ]);
    if (picked == null || !mounted) return;
    setState(() => _colours = [..._colours, picked]);
  }

  /// Removing a saved photo takes effect at once (it is a delete on the
  /// server), the same as it always has from the products list.
  Future<void> _removeLiveImage(ProductImage image) async {
    final product = _product;
    if (product == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(adminProductsControllerProvider.notifier)
          .removeImage(product.id, image.publicId);
      if (mounted) {
        setState(() {
          _product = updated;
          _liveImages = [...updated.images];
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One stock box per colour × size. With neither, a single box: a ball or
  /// a pair of socks is still one buyable option.
  Widget _stockGrid(AppLocalizations l10n) {
    final colours = _colours.isEmpty ? <ProductColour?>[null] : _colours;
    final sizes = _sizes.isEmpty ? <String?>[null] : _sizes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final colour in colours)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: colour == null
                      ? Text(l10n.adminProductStockLabel)
                      : Row(
                          children: [
                            ColourDot(hex: colour.hex, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                colour.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final size in sizes)
                        SizedBox(
                          width: 84,
                          child: TextFormField(
                            controller: _stockFor(colour?.name, size),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: size ?? l10n.adminProductStockLabel,
                            ),
                            validator: (value) =>
                                int.tryParse((value ?? '').trim()) == null
                                ? l10n.adminWholeNumberError
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _variantsBody() {
    final colours = _colours.isEmpty
        ? <String?>[null]
        : [for (final c in _colours) c.name];
    final sizes = _sizes.isEmpty ? <String?>[null] : _sizes;
    return [
      for (final colour in colours)
        for (final size in sizes)
          {
            'size': ?size,
            'colour': ?colour,
            'sku': ?_skus[_key(colour, size)],
            'stock': int.tryParse(_stockFor(colour, size).text.trim()) ?? 0,
          },
    ];
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
      'variants': _variantsBody(),
      'colours': [
        for (final c in _colours) {'name': c.name, 'hex': c.hex},
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
      var latest = existing == null
          ? await controller.create(body)
          : await (() async {
              await controller.save(existing.id, body);
              return existing;
            })();

      // Photos go up after the product (and its colours) are saved, in the
      // order picked; the first general photo is the one tiles show.
      final failed = <String>[];
      final remaining = <String?, List<PlatformFile>>{};
      for (final entry in _pending.entries) {
        for (final file in entry.value) {
          try {
            latest = await controller.addImage(
              latest.id,
              file.bytes!,
              file.name,
              colour: entry.key,
            );
          } catch (_) {
            failed.add(file.name);
            (remaining[entry.key] ??= []).add(file);
          }
        }
      }
      if (!mounted) return;
      if (failed.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      // The product is saved; stay open on it with what did upload, and
      // keep the failed photos queued so Save tries them again.
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _product = latest;
        _liveImages = [...latest.images];
        _pending
          ..clear()
          ..addAll(remaining);
        _error = l10n.adminProductSomePhotosFailed(failed.join('، '));
      });
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
