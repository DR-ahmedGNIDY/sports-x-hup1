import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/admin_banner.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

/// The storefront hero. Each banner carries two images — one composed for a
/// wide screen, one for a phone — because a desktop crop puts its subject
/// where a phone cuts it off.
class AdminStoreBannersTab extends ConsumerWidget {
  const AdminStoreBannersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(adminBannersControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Banners rotate on the store home page, in this order. '
                  'A banner appears only once it has a desktop image.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const _BannerEditor(banner: null),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New banner'),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<AdminBanner>(
            value: banners,
            emptyMessage:
                'No banners yet — the store shows an empty hero band.',
            onRetry: () => ref.invalidate(adminBannersControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _BannerRow(banner: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerRow extends ConsumerWidget {
  const _BannerRow({required this.banner});

  final AdminBanner banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final withheld = banner.withheldReason;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shown side by side and labelled, so "which one is missing" is
          // answered by looking rather than by clicking in.
          _Slot(
            label: 'Desktop',
            url: banner.desktopUrl,
            width: 160,
            // Required: it is what makes the banner publishable, so it can
            // be replaced but not cleared.
            onClear: null,
            onPick: () => _pick(context, ref, 'desktop'),
          ),
          const SizedBox(width: 12),
          _Slot(
            label: 'Mobile',
            url: banner.mobileUrl,
            width: 72,
            hint: banner.mobileUrl == null ? 'Falls back to desktop' : null,
            onClear: banner.mobileUrl == null
                ? null
                : () => ref
                      .read(adminBannersControllerProvider.notifier)
                      .removeImage(banner.id, 'mobile'),
            onPick: () => _pick(context, ref, 'mobile'),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.alt?.en ?? 'No description',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: banner.alt == null ? scheme.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ${banner.sortOrder}'
                  '${banner.linkPath == null ? '' : '  ·  links to ${banner.linkPath}'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (withheld != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        size: 14,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 6),
                      // Says why rather than leaving the merchant to work
                      // out why their banner is not on the site.
                      Text(
                        'Not on the store — $withheld',
                        style: TextStyle(fontSize: 12, color: scheme.error),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => _BannerEditor(banner: banner),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: banner.isActive ? 'Switch off' : 'Already off',
            onPressed: banner.isActive
                ? () => ref
                      .read(adminBannersControllerProvider.notifier)
                      .deactivate(banner.id)
                : null,
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, String slot) async {
    // Captured before the picker's await: after it, this BuildContext may no
    // longer be mounted.
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.singleOrNull;
    final bytes = file?.bytes;
    if (bytes == null) return;

    try {
      await ref
          .read(adminBannersControllerProvider.notifier)
          .setImage(banner.id, slot, bytes, file!.name);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

/// One of a banner's two image slots. The two are shown at their own
/// proportions — wide for desktop, tall for mobile — so the merchant can see
/// at a glance that they are different crops rather than the same picture.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.label,
    required this.url,
    required this.width,
    required this.onPick,
    required this.onClear,
    this.hint,
  });

  final String label;
  final String? url;
  final double width;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          InkWell(
            onTap: onPick,
            child: SizedBox(
              height: 72,
              child: url == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outlineVariant),
                        color: scheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 18,
                          color: scheme.outline,
                        ),
                      ),
                    )
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                      ),
                    ),
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _BannerEditor extends ConsumerStatefulWidget {
  const _BannerEditor({required this.banner});

  final AdminBanner? banner;

  @override
  ConsumerState<_BannerEditor> createState() => _BannerEditorState();
}

class _BannerEditorState extends ConsumerState<_BannerEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _altEn = TextEditingController(text: widget.banner?.alt?.en);
  late final _altAr = TextEditingController(text: widget.banner?.alt?.ar);
  late final _linkPath = TextEditingController(text: widget.banner?.linkPath);
  late final _sortOrder = TextEditingController(
    text: '${widget.banner?.sortOrder ?? 0}',
  );
  late bool _isActive = widget.banner?.isActive ?? true;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_altEn, _altAr, _linkPath, _sortOrder]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.banner == null;

    return AlertDialog(
      title: Text(isNew ? 'New banner' : 'Edit banner'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isNew)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      // The images need the banner to exist first, so its
                      // folder can be named after it.
                      'Save this first, then upload its images from the list.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                TextFormField(
                  controller: _altEn,
                  decoration: const InputDecoration(
                    labelText: 'Description (English)',
                    helperText: 'Read aloud by screen readers',
                  ),
                ),
                TextFormField(
                  controller: _altAr,
                  decoration: const InputDecoration(
                    labelText: 'Description (Arabic)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _linkPath,
                  decoration: const InputDecoration(
                    labelText: 'Links to (optional)',
                    helperText: 'A store path, e.g. /c/men or /p/black-shorts',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    // Matches the server's own rule. A full URL here would
                    // be a redirect off the store.
                    if (!RegExp(r'^/(?!/)[A-Za-z0-9\-._~/]*$').hasMatch(text)) {
                      return 'A store path starting with / — not a full URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sortOrder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Order',
                    helperText: 'Lower numbers show first',
                  ),
                  validator: (value) =>
                      int.tryParse((value ?? '').trim()) == null
                      ? 'A whole number'
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final altEn = _altEn.text.trim();
    final body = <String, dynamic>{
      // The Arabic half alone cannot be sent: the server's LocalizedText
      // requires English, so an Arabic-only description would be rejected.
      if (altEn.isNotEmpty)
        'alt': {
          'en': altEn,
          if (_altAr.text.trim().isNotEmpty) 'ar': _altAr.text.trim(),
        },
      if (_linkPath.text.trim().isNotEmpty) 'linkPath': _linkPath.text.trim(),
      'sortOrder': int.parse(_sortOrder.text.trim()),
      'isActive': _isActive,
    };

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(adminBannersControllerProvider.notifier);
      if (widget.banner == null) {
        await controller.create(body);
      } else {
        await controller.save(widget.banner!.id, body);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
