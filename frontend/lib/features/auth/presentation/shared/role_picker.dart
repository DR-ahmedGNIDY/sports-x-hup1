import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/user_role.dart';

/// Leaf atom — see AuthErrorBanner for why this is shared, not duplicated.
class RolePicker extends StatelessWidget {
  const RolePicker({super.key, required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<UserRole>(
      segments: [
        ButtonSegment(
          value: UserRole.player,
          label: Text(l10n.rolePlayer),
          icon: const Icon(Icons.sports_soccer_outlined),
        ),
        ButtonSegment(
          value: UserRole.club,
          label: Text(l10n.roleClub),
          icon: const Icon(Icons.shield_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
