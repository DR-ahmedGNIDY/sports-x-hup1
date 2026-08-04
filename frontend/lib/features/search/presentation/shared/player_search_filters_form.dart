import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/application/lookup_providers.dart';
import '../../../player/domain/entities/player_enums.dart';
import '../../domain/entities/player_search_filters.dart';

/// The 7 filters from the roadmap (Country, Age, Position, Height, Weight,
/// Preferred Foot, Sport). Shared by the Desktop filter sidebar and the
/// Mobile filter sheet — only the surrounding chrome differs between them.
class PlayerSearchFiltersForm extends ConsumerStatefulWidget {
  const PlayerSearchFiltersForm({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  final PlayerSearchFilters initialFilters;
  final ValueChanged<PlayerSearchFilters> onApply;

  @override
  ConsumerState<PlayerSearchFiltersForm> createState() =>
      _PlayerSearchFiltersFormState();
}

class _PlayerSearchFiltersFormState extends ConsumerState<PlayerSearchFiltersForm> {
  late final _minAge = TextEditingController(
    text: widget.initialFilters.minAge?.toString() ?? '',
  );
  late final _maxAge = TextEditingController(
    text: widget.initialFilters.maxAge?.toString() ?? '',
  );
  late final _position = TextEditingController(text: widget.initialFilters.position ?? '');
  late final _minHeight = TextEditingController(
    text: widget.initialFilters.minHeight?.toString() ?? '',
  );
  late final _maxHeight = TextEditingController(
    text: widget.initialFilters.maxHeight?.toString() ?? '',
  );
  late final _weight = TextEditingController(
    text: widget.initialFilters.weight?.toString() ?? '',
  );
  late String? _country = widget.initialFilters.country;
  late String? _sport = widget.initialFilters.sport;
  late PreferredFoot? _preferredFoot = widget.initialFilters.preferredFoot;

  @override
  void dispose() {
    _minAge.dispose();
    _maxAge.dispose();
    _position.dispose();
    _minHeight.dispose();
    _maxHeight.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      PlayerSearchFilters(
        country: _country,
        minAge: int.tryParse(_minAge.text),
        maxAge: int.tryParse(_maxAge.text),
        position: _position.text.trim().isEmpty ? null : _position.text.trim(),
        minHeight: int.tryParse(_minHeight.text),
        maxHeight: int.tryParse(_maxHeight.text),
        weight: int.tryParse(_weight.text),
        preferredFoot: _preferredFoot,
        sport: _sport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sports = ref.watch(sportsProvider);
    final countries = ref.watch(countriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Filters', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        sports.when(
          data: (options) => DropdownButtonFormField<String>(
            initialValue: _sport,
            decoration: const InputDecoration(labelText: 'Sport'),
            items: [
              const DropdownMenuItem<String>(child: Text('Any')),
              ...options.map((o) => DropdownMenuItem(value: o.name, child: Text(o.name))),
            ],
            onChanged: (value) => setState(() => _sport = value),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _position,
          decoration: const InputDecoration(labelText: 'Position'),
        ),
        const SizedBox(height: 12),
        countries.when(
          data: (options) => DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: const InputDecoration(labelText: 'Country'),
            items: [
              const DropdownMenuItem<String>(child: Text('Any')),
              ...options.map((o) => DropdownMenuItem(value: o.name, child: Text(o.name))),
            ],
            onChanged: (value) => setState(() => _country = value),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min age'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxAge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max age'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minHeight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min height (cm)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxHeight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max height (cm)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weight,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PreferredFoot>(
          initialValue: _preferredFoot,
          decoration: const InputDecoration(labelText: 'Preferred foot'),
          items: [
            const DropdownMenuItem<PreferredFoot>(child: Text('Any')),
            ...PreferredFoot.values.map(
              (f) => DropdownMenuItem(value: f, child: Text(f.label)),
            ),
          ],
          onChanged: (value) => setState(() => _preferredFoot = value),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _apply, child: const Text('Apply filters')),
      ],
    );
  }
}
