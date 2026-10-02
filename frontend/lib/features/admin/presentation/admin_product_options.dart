import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_product.dart';

/// The colours offered in one tap. Names are what the storefront shows and
/// what ties a colour to its photos and stock, so they are Arabic like the
/// rest of the store.
const productColourPresets = <ProductColour>[
  ProductColour(name: 'أسود', hex: '#000000'),
  ProductColour(name: 'أبيض', hex: '#ffffff'),
  ProductColour(name: 'رمادي', hex: '#9e9e9e'),
  ProductColour(name: 'كحلي', hex: '#1a237e'),
  ProductColour(name: 'أزرق', hex: '#1976d2'),
  ProductColour(name: 'سماوي', hex: '#4fc3f7'),
  ProductColour(name: 'أحمر', hex: '#d32f2f'),
  ProductColour(name: 'نبيتي', hex: '#7b1f2e'),
  ProductColour(name: 'وردي', hex: '#ec407a'),
  ProductColour(name: 'برتقالي', hex: '#f57c00'),
  ProductColour(name: 'أصفر', hex: '#fbc02d'),
  ProductColour(name: 'أخضر', hex: '#388e3c'),
  ProductColour(name: 'زيتي', hex: '#556b2f'),
  ProductColour(name: 'بيج', hex: '#d7c4a3'),
  ProductColour(name: 'بني', hex: '#6d4c41'),
  ProductColour(name: 'بنفسجي', hex: '#7b1fa2'),
];

Color colourFromHex(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0x9e9e9e;
  return Color(0xFF000000 | value);
}

/// A round swatch with a hairline, so white reads on a white dialog.
class ColourDot extends StatelessWidget {
  const ColourDot({super.key, required this.hex, this.size = 22});

  final String hex;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colourFromHex(hex),
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
  );
}

/// Asks for a colour: a preset in one tap, or "another colour" with its own
/// name and shade. Colours already on the product are left out.
Future<ProductColour?> pickProductColour(
  BuildContext context,
  List<String> taken,
) => showDialog<ProductColour>(
  context: context,
  builder: (context) => _ColourPickerDialog(taken: taken),
);

class _ColourPickerDialog extends StatefulWidget {
  const _ColourPickerDialog({required this.taken});

  final List<String> taken;

  @override
  State<_ColourPickerDialog> createState() => _ColourPickerDialogState();
}

class _ColourPickerDialogState extends State<_ColourPickerDialog> {
  bool _custom = false;
  final _name = TextEditingController();
  String _hex = productColourPresets.first.hex;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final available = productColourPresets
        .where((c) => !widget.taken.contains(c.name))
        .toList();
    final name = _name.text.trim();
    final nameTaken = widget.taken.contains(name);

    return AlertDialog(
      title: Text(l10n.adminColourAdd),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: !_custom
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in available)
                      ActionChip(
                        avatar: ColourDot(hex: c.hex, size: 18),
                        label: Text(c.name),
                        onPressed: () => Navigator.of(context).pop(c),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.palette_outlined, size: 18),
                      label: Text(l10n.adminColourOther),
                      onPressed: () => setState(() => _custom = true),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _name,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.adminColourName,
                        errorText: nameTaken ? l10n.adminColourTaken : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.adminColourShade),
                    const SizedBox(height: 8),
                    // The presets double as the shade palette: a custom
                    // colour usually only needs a different name ("فوشيا")
                    // on a familiar shade.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in productColourPresets)
                          InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _hex = c.hex),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 2,
                                  color: _hex == c.hex
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: ColourDot(hex: c.hex, size: 28),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        if (_custom)
          FilledButton(
            onPressed: name.isEmpty || nameTaken
                ? null
                : () => Navigator.of(
                    context,
                  ).pop(ProductColour(name: name, hex: _hex)),
            child: Text(l10n.adminColourAdd),
          ),
      ],
    );
  }
}

/// One colour's photos (or the general ones): what is already on the
/// product, what is waiting to upload on save, and a tile to add more.
class ProductPhotoStrip extends StatelessWidget {
  const ProductPhotoStrip({
    super.key,
    required this.live,
    required this.pending,
    required this.onPendingChanged,
    required this.onRemoveLive,
    required this.enabled,
  });

  final List<ProductImage> live;
  final List<PlatformFile> pending;
  final ValueChanged<List<PlatformFile>> onPendingChanged;
  final ValueChanged<ProductImage> onRemoveLive;
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
    if (chosen.isNotEmpty) onPendingChanged([...pending, ...chosen]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final image in live)
          _PhotoThumb(
            image: NetworkImage(image.url),
            onRemove: enabled ? () => onRemoveLive(image) : null,
          ),
        for (var i = 0; i < pending.length; i++)
          _PhotoThumb(
            image: MemoryImage(pending[i].bytes!),
            onRemove: enabled
                ? () => onPendingChanged([...pending]..removeAt(i))
                : null,
          ),
        SizedBox(
          width: 72,
          height: 96,
          child: OutlinedButton(
            onPressed: enabled ? _pick : null,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 20),
                const SizedBox(height: 4),
                Text(
                  l10n.adminUploadLabel,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.image, required this.onRemove});

  final ImageProvider image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 72,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            child: IconButton(
              tooltip: l10n.adminProductRemoveImageTooltip,
              onPressed: onRemove,
              iconSize: 14,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sizes as removable chips with a field to add one ("S", "42", ...).
class SizesInput extends StatefulWidget {
  const SizesInput({super.key, required this.sizes, required this.onChanged});

  final List<String> sizes;
  final ValueChanged<List<String>> onChanged;

  @override
  State<SizesInput> createState() => _SizesInputState();
}

class _SizesInputState extends State<SizesInput> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _add() {
    // Commas let a whole range go in at once: "S, M, L, XL".
    final added = _field.text
        .split(RegExp(r'[,،]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !widget.sizes.contains(s))
        .toSet()
        .toList();
    _field.clear();
    if (added.isNotEmpty) widget.onChanged([...widget.sizes, ...added]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _field,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.adminSizesField,
                  hintText: 'S, M, L, XL',
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.adminSizesAdd),
            ),
          ],
        ),
        if (widget.sizes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final size in widget.sizes)
                InputChip(
                  label: Text(size),
                  onDeleted: () => widget.onChanged(
                    widget.sizes.where((s) => s != size).toList(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
