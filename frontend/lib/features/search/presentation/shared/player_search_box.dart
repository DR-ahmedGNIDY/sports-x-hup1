import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/search_controller.dart';

/// Name search box for Find Players — separate from the Sport/Position/etc.
/// filter form (sidebar on Desktop, bottom sheet on Mobile), since a name
/// search is the primary, always-visible entry point per the brief, not
/// something buried behind a filter panel. Debounced 400ms, same pattern
/// as `ClubPlayersToolbar`'s search field.
class PlayerSearchBox extends ConsumerStatefulWidget {
  const PlayerSearchBox({super.key});

  @override
  ConsumerState<PlayerSearchBox> createState() => _PlayerSearchBoxState();
}

class _PlayerSearchBoxState extends ConsumerState<PlayerSearchBox> {
  late final _controller = TextEditingController(
    text: ref.read(searchControllerProvider.notifier).filters.search ?? '',
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleApply() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(searchControllerProvider.notifier).updateSearch(_controller.text),
    );
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    _debounce?.cancel();
    ref.read(searchControllerProvider.notifier).updateSearch(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: l10n.playerSearchNameLabel,
        prefixIcon: const Icon(Icons.search_outlined),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.close_outlined), onPressed: _clear),
      ),
      onChanged: (_) {
        setState(() {}); // toggles the clear button
        _scheduleApply();
      },
    );
  }
}
