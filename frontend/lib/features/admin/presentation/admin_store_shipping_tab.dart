import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/shipping_zone.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

/// Delivery fees per governorate.
///
/// Read-and-edit only — there is no "add zone" here. The 27 governorates
/// are seeded once (`npm run seed:shipping`) and the merchant's job is to
/// price them, not to invent new ones.
class AdminStoreShippingTab extends ConsumerWidget {
  const AdminStoreShippingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(adminShippingControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Turning a governorate off removes it from checkout. Orders '
            'already delivered there keep their fee.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: AdminAsyncList<ShippingZone>(
            value: zones,
            emptyMessage:
                'No governorates yet — run the shipping seed on the server.',
            onRetry: () => ref.invalidate(adminShippingControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _ZoneRow(zone: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneRow extends ConsumerStatefulWidget {
  const _ZoneRow({required this.zone});

  final ShippingZone zone;

  @override
  ConsumerState<_ZoneRow> createState() => _ZoneRowState();
}

class _ZoneRowState extends ConsumerState<_ZoneRow> {
  late final _fee = TextEditingController(
    text: minorToPounds(widget.zone.feeMinor),
  );
  late bool _isActive = widget.zone.isActive ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _fee.dispose();
    super.dispose();
  }

  /// True when the row differs from what the server holds — the Save button
  /// only lights up then, so a table of 27 rows has one obvious action.
  bool get _isDirty {
    final typed = poundsToMinor(_fee.text);
    return (typed != null && typed != widget.zone.feeMinor) ||
        _isActive != (widget.zone.isActive ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.zone.name.en),
                Text(
                  widget.zone.name.ar ?? '—',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _fee,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Fee (EGP)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 130,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Deliver', style: TextStyle(fontSize: 12)),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy || !_isDirty ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final feeMinor = poundsToMinor(_fee.text);
    final messenger = ScaffoldMessenger.of(context);
    if (feeMinor == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a fee like 65.00')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(adminShippingControllerProvider.notifier)
          .save(widget.zone, feeMinor: feeMinor, isActive: _isActive);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
