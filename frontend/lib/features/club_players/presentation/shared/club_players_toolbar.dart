import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/lookup_providers.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/club_players_filters.dart';

/// Search (name/phone) + Sport/Position filters for the Club Players
/// roster — all server-side (`ClubPlayersController.applyFilters`), never
/// a client-side filter over an already-downloaded list. Every field
/// change is debounced 400ms into one combined `applyFilters` call, so
/// typing a search query or picking a filter doesn't fire a request per
/// keystroke/change.
class ClubPlayersToolbar extends ConsumerStatefulWidget {
  const ClubPlayersToolbar({super.key});

  @override
  ConsumerState<ClubPlayersToolbar> createState() => _ClubPlayersToolbarState();
}

class _ClubPlayersToolbarState extends ConsumerState<ClubPlayersToolbar> {
  late final _search = TextEditingController(
    text: ref.read(clubPlayersControllerProvider.notifier).filters.search ?? '',
  );
  late final _position = TextEditingController(
    text: ref.read(clubPlayersControllerProvider.notifier).filters.position ?? '',
  );
  String? _sport;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _sport = ref.read(clubPlayersControllerProvider.notifier).filters.sport;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _position.dispose();
    super.dispose();
  }

  void _scheduleApply() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _apply);
  }

  void _apply() {
    ref
        .read(clubPlayersControllerProvider.notifier)
        .applyFilters(
          search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          sport: _sport,
          position: _position.text.trim().isEmpty ? null : _position.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sports = ref.watch(sportsProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: l10n.clubPlayersSearchLabel,
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearchLabel,
                      icon: const Icon(Icons.close_outlined),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                        _apply();
                      },
                    ),
            ),
            onChanged: (_) {
              setState(() {}); // toggles the clear button
              _scheduleApply();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: sports.when(
            data: (options) => DropdownButtonFormField<String>(
              initialValue: _sport,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.clubPlayersSportFilterLabel),
              items: [
                DropdownMenuItem<String>(value: null, child: Text(l10n.clubPlayersAnyFilterOption)),
                ...options.map((o) => DropdownMenuItem(value: o.name, child: Text(o.name))),
              ],
              onChanged: (value) {
                setState(() => _sport = value);
                _apply();
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _position,
            decoration: InputDecoration(labelText: l10n.clubPlayersPositionFilterLabel),
            onChanged: (_) => _scheduleApply(),
          ),
        ),
      ],
    );
  }
}

/// A filter is active whenever any of search/sport/position is set —
/// used to pick between the "no players yet" and "no results for these
/// filters" empty states.
bool clubPlayersFiltersActive(ClubPlayersFilters filters) =>
    (filters.search?.isNotEmpty ?? false) ||
    (filters.sport?.isNotEmpty ?? false) ||
    (filters.position?.isNotEmpty ?? false);
