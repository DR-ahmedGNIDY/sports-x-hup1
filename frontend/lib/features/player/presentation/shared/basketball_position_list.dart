import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/basketball_position.dart';

/// Perimeter-to-interior display order for the selectable position list.
const List<String> basketballPositionListOrder = ['PG', 'SG', 'SF', 'PF', 'C'];

/// The selectable list of positions used in Edit Profile: a vertical rail
/// of rows (code, name, short description) with the same tap-to-set-
/// primary / long-press-to-toggle-secondary gestures as the court
/// markers in [BasketballCourtCanvas] — both are driven by the same
/// [positions] state so they always agree.
class BasketballPositionList extends StatelessWidget {
  const BasketballPositionList({
    super.key,
    required this.positions,
    required this.onTap,
    required this.onLongPress,
  });

  final List<String> positions;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = positions.isNotEmpty ? positions.first : null;
    final secondary = positions.length > 1 ? positions.sublist(1).toSet() : const <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final code in basketballPositionListOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PositionRow(
              code: code,
              name: basketballPositionFullName(l10n, code),
              description: basketballPositionDescription(l10n, code),
              isPrimary: code == primary,
              isSecondary: secondary.contains(code),
              onTap: () => onTap(code),
              onLongPress: () => onLongPress(code),
            ),
          ),
      ],
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.code,
    required this.name,
    required this.description,
    required this.isPrimary,
    required this.isSecondary,
    required this.onTap,
    required this.onLongPress,
  });

  final String code;
  final String name;
  final String description;
  final bool isPrimary;
  final bool isSecondary;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = isPrimary
        ? AppColors.pitchPrimary
        : isSecondary
        ? AppColors.success
        : null;

    return Semantics(
      label: name,
      button: true,
      selected: isPrimary || isSecondary,
      child: Material(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent ?? Colors.white.withValues(alpha: 0.08), width: accent != null ? 1.4 : 1),
              boxShadow: accent != null
                  ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: -2)]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent ?? AppColors.offWhite,
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: accent != null ? AppColors.white : AppColors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isPrimary)
                  const Icon(Icons.check_circle, color: AppColors.pitchPrimary, size: 20)
                else if (isSecondary)
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
