import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/store_category.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

class AdminStoreCategoriesTab extends ConsumerWidget {
  const AdminStoreCategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(adminCategoriesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Order here is the order they appear in the store nav.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showEditor(context, ref, null, categories),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New category'),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreCategory>(
            value: categories,
            emptyMessage: 'No categories yet.',
            onRetry: () => ref.invalidate(adminCategoriesControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _CategoryRow(
                category: items[index],
                all: items,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showEditor(
  BuildContext context,
  WidgetRef ref,
  StoreCategory? category,
  AsyncValue<List<StoreCategory>> categories,
) => showDialog<void>(
  context: context,
  builder: (context) => _CategoryEditor(
    category: category,
    all: categories.valueOrNull ?? const [],
  ),
);

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category, required this.all});

  final StoreCategory category;
  final List<StoreCategory> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final parent = category.parentId == null
        ? null
        : all.where((c) => c.id == category.parentId).firstOrNull;
    final isVisible = category.isActive ?? true;

    return ListTile(
      // Children are indented rather than nested in an expander: the nav is
      // one level deep, so a tree widget would be scaffolding for nothing.
      contentPadding: EdgeInsetsDirectional.only(
        start: parent == null ? 16 : 48,
        end: 16,
      ),
      leading: SizedBox(
        width: 44,
        height: 44,
        child: category.imageUrl == null
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: scheme.outline,
                ),
              )
            : Image.network(
                category.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHighest),
              ),
      ),
      title: Text(category.name.en),
      subtitle: Text(
        '/${category.slug}'
        '${category.name.ar == null ? '  ·  no Arabic name' : ''}'
        '${isVisible ? '' : '  ·  Hidden'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Set image',
            onPressed: () => _pickImage(context, ref),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) =>
                  _CategoryEditor(category: category, all: all),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    // Captured before the picker's await: after it, this BuildContext may
    // no longer be mounted and reading from it is undefined.
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
          .read(adminCategoriesControllerProvider.notifier)
          .setImage(category.id, bytes, file!.name);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.category, required this.all});

  final StoreCategory? category;
  final List<StoreCategory> all;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _nameEn = TextEditingController(text: widget.category?.name.en);
  late final _nameAr = TextEditingController(text: widget.category?.name.ar);
  late final _sortOrder = TextEditingController(
    text: '${widget.category?.sortOrder ?? 0}',
  );
  late String? _parentId = widget.category?.parentId;
  late bool _isActive = widget.category?.isActive ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only top-level categories can be parents (the nav is one level deep),
    // and a category cannot parent itself.
    final parents = widget.all
        .where((c) => c.parentId == null && c.id != widget.category?.id)
        .toList();

    return AlertDialog(
      title: Text(
        widget.category == null ? 'New category' : 'Edit category',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameEn,
                decoration: const InputDecoration(labelText: 'Name (English)'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _nameAr,
                decoration: const InputDecoration(labelText: 'Name (Arabic)'),
              ),
              DropdownButtonFormField<String?>(
                initialValue: parents.any((c) => c.id == _parentId)
                    ? _parentId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Parent (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Top level')),
                  for (final parent in parents)
                    DropdownMenuItem(
                      value: parent.id,
                      child: Text(parent.name.en),
                    ),
                ],
                onChanged: (value) => setState(() => _parentId = value),
              ),
              TextFormField(
                controller: _sortOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sort order'),
                validator: (value) =>
                    int.tryParse((value ?? '').trim()) == null
                    ? 'Whole number'
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible'),
                subtitle: const Text('Shows in the store nav'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (widget.category != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    // Worth saying plainly, because it is surprising: the
                    // rename lands but the URL does not follow.
                    'Renaming does not change the URL — the slug is fixed '
                    'once created so existing links keep working.',
                    style: TextStyle(fontSize: 12),
                  ),
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

    final body = <String, dynamic>{
      'name': {
        'en': _nameEn.text.trim(),
        if (_nameAr.text.trim().isNotEmpty) 'ar': _nameAr.text.trim(),
      },
      if (_parentId != null) 'parentId': _parentId,
      'sortOrder': int.parse(_sortOrder.text.trim()),
      'isActive': _isActive,
    };

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(adminCategoriesControllerProvider.notifier);
      if (widget.category == null) {
        await controller.create(body);
      } else {
        await controller.save(widget.category!.id, body);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
