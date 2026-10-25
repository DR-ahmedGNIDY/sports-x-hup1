import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/localized_text.dart';
import '../../store/domain/entities/shipping_zone.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

/// Delivery fees per governorate, and per city inside each governorate.
///
/// Governorates themselves are read-and-edit only — there is no "add zone"
/// here. The 27 governorates are seeded once (`npm run seed:shipping`) and
/// the merchant's job is to price them. Cities are the opposite: the
/// merchant adds exactly the ones they want to price individually, and any
/// city left unlisted still ships at the governorate's flat fee above.
class AdminStoreShippingTab extends ConsumerWidget {
  const AdminStoreShippingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final zones = ref.watch(adminShippingControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.adminShippingIntro,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: AdminAsyncList<ShippingZone>(
            value: zones,
            emptyMessage: l10n.adminShippingEmpty,
            onRetry: () => ref.invalidate(adminShippingControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _ZoneTile(zone: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// A governorate's own row, expandable into the cities priced inside it.
class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.zone});

  final ShippingZone zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: _ZoneRow(zone: zone),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.adminShippingCitiesLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 4),
        if (zone.cities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.adminShippingCitiesEmpty,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...zone.cities.map((city) => _CityRow(zone: zone, city: city)),
        const SizedBox(height: 8),
        _AddCityForm(zone: zone),
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
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
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.adminShippingFeeLabel,
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
            title: Text(l10n.adminShippingDeliverLabel, style: const TextStyle(fontSize: 12)),
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
              : Text(l10n.saveLabel),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final feeMinor = poundsToMinor(_fee.text);
    final messenger = ScaffoldMessenger.of(context);
    if (feeMinor == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminShippingFeeExampleError)),
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

/// One priced city, editable exactly like a zone row — same fee field,
/// active switch and dirty-tracked Save button.
class _CityRow extends ConsumerStatefulWidget {
  const _CityRow({required this.zone, required this.city});

  final ShippingZone zone;
  final ShippingCity city;

  @override
  ConsumerState<_CityRow> createState() => _CityRowState();
}

class _CityRowState extends ConsumerState<_CityRow> {
  late final _fee = TextEditingController(
    text: minorToPounds(widget.city.feeMinor),
  );
  late bool _isActive = widget.city.isActive ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _fee.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final typed = poundsToMinor(_fee.text);
    return (typed != null && typed != widget.city.feeMinor) ||
        _isActive != (widget.city.isActive ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.city.name.en),
                Text(
                  widget.city.name.ar ?? '—',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _fee,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.adminShippingFeeLabel,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.adminShippingDeliverLabel, style: const TextStyle(fontSize: 12)),
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
                : Text(l10n.saveLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final feeMinor = poundsToMinor(_fee.text);
    final messenger = ScaffoldMessenger.of(context);
    if (feeMinor == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminShippingFeeExampleError)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(adminShippingControllerProvider.notifier)
          .saveCity(
            widget.zone,
            widget.city,
            feeMinor: feeMinor,
            isActive: _isActive,
          );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Adds one new city to a governorate. There is no delete, same as a zone —
/// a city priced once may already sit on a past order.
class _AddCityForm extends ConsumerStatefulWidget {
  const _AddCityForm({required this.zone});

  final ShippingZone zone;

  @override
  ConsumerState<_AddCityForm> createState() => _AddCityFormState();
}

class _AddCityFormState extends ConsumerState<_AddCityForm> {
  final _nameEn = TextEditingController();
  final _nameAr = TextEditingController();
  final _code = TextEditingController();
  final _fee = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _code.dispose();
    _fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _nameEn,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.adminCityNameEnLabel,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _nameAr,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.adminCityNameArLabel,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _code,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.adminCityCodeLabel,
              hintText: l10n.adminCityCodeHint,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _fee,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.adminShippingFeeLabel,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: _busy ? null : _add,
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.adminShippingAddCityLabel),
        ),
      ],
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nameEn = _nameEn.text.trim();
    final code = _code.text.trim().toLowerCase();
    final feeMinor = poundsToMinor(_fee.text);
    final codeOk = RegExp(r'^[a-z0-9-]+$').hasMatch(code);

    if (nameEn.isEmpty || !codeOk || feeMinor == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminCityFormError)));
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(adminShippingControllerProvider.notifier)
          .addCity(
            widget.zone,
            name: LocalizedText(
              en: nameEn,
              ar: _nameAr.text.trim().isEmpty ? null : _nameAr.text.trim(),
            ),
            code: code,
            feeMinor: feeMinor,
          );
      _nameEn.clear();
      _nameAr.clear();
      _code.clear();
      _fee.clear();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
