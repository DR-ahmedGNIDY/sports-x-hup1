import 'package:flutter/material.dart';

import '../../domain/entities/user_role.dart';

/// Leaf atom — see AuthErrorBanner for why this is shared, not duplicated.
class RolePicker extends StatelessWidget {
  const RolePicker({super.key, required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment(
          value: UserRole.player,
          label: Text('Player'),
          icon: Icon(Icons.sports_soccer_outlined),
        ),
        ButtonSegment(
          value: UserRole.club,
          label: Text('Club'),
          icon: Icon(Icons.shield_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
