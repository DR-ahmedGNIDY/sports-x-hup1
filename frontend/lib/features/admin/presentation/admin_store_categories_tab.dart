import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_category.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

class AdminStoreCategoriesTab extends ConsumerWidget {
  const AdminStoreCategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(adminCategoriesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminCategoryOrderHint,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showEditor(context, ref, null, categories),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.adminCategoryNew),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreCategory>(
            value: categories,
            emptyMessage: l10n.adminCategoriesEmpty,
            onRetry: () => ref.invalidate(adminCategoriesControllerProvider),
            builder: (context, items) {
              final ordered = categoryTree(items);
              return ListView.separated(
                itemCount: ordered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _CategoryRow(category: ordered[index], all: items),
              );
            },
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
    final l10n = AppLocalizations.of(context)!;
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
      title: Text(category.name.resolve(true)),
      subtitle: Text(
        '/${category.slug}'
        '${isVisible ? '' : l10n.adminCategoryHiddenSuffix}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.adminSetImageTooltip,
            onPressed: () => _pickImage(context, ref),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          ),
          IconButton(
            tooltip: l10n.editLabel,
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
  late final _nameAr = TextEditingController(
    text: widget.category?.name.resolve(true),
  );
  late final _sortOrder = TextEditingController(
    text: '${widget.category?.sortOrder ?? 0}',
  );
  late String? _parentId = widget.category?.parentId;
  late bool _isActive = widget.category?.isActive ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameAr.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Only top-level categories can be parents (the nav is one level deep),
    // and a category cannot parent itself.
    final parents = widget.all
        .where((c) => c.parentId == null && c.id != widget.category?.id)
        .toList();

    return AlertDialog(
      title: Text(
        widget.category == null
            ? l10n.adminCategoryNew
            : l10n.adminCategoryEdit,
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameAr,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: l10n.adminCategoryNameAr,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.storeRequiredField
                    : null,
              ),
              DropdownButtonFormField<String?>(
                initialValue: parents.any((c) => c.id == _parentId)
                    ? _parentId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.adminCategoryParentLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.adminCategoryTopLevel),
                  ),
                  for (final parent in parents)
                    DropdownMenuItem(
                      value: parent.id,
                      child: Text(parent.name.resolve(true)),
                    ),
                ],
                onChanged: (value) => setState(() => _parentId = value),
              ),
              TextFormField(
                controller: _sortOrder,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.adminCategorySortOrderLabel,
                ),
                validator: (value) => int.tryParse((value ?? '').trim()) == null
                    ? l10n.adminWholeNumberError
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.adminVisibleLabel),
                subtitle: Text(l10n.adminCategoryVisibleHint),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (widget.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    // Worth saying plainly, because it is surprising: the
                    // rename lands but the URL does not follow.
                    l10n.adminCategoryRenameHint,
                    style: const TextStyle(fontSize: 12),
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final arabic = _nameAr.text.trim();
    final body = <String, dynamic>{
      'name': {
        // The store is Arabic-first and the admin types Arabic only. The API
        // still requires `en`: an existing category keeps the English name
        // it has (the English site shows it), a new one reuses the Arabic.
        'en': widget.category?.name.en ?? arabic,
        'ar': arabic,
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

/// Departments in their own order, each followed by its own shelves — the
/// API returns one flat list sorted by `sortOrder` alone, which interleaved
/// every department's shelves (sortOrder 0, 1, 2) right after the first
/// department and made them all look like its children.
List<StoreCategory> categoryTree(List<StoreCategory> items) {
  int bySort(StoreCategory a, StoreCategory b) =>
      a.sortOrder.compareTo(b.sortOrder);
  final ids = {for (final c in items) c.id};
  // A child whose parent is missing from the list is shown as top-level
  // rather than dropped.
  final roots =
      items
          .where((c) => c.parentId == null || !ids.contains(c.parentId))
          .toList()
        ..sort(bySort);
  return [
    for (final root in roots) ...[
      root,
      ...(items.where((c) => c.parentId == root.id).toList()..sort(bySort)),
    ],
  ];
}
