import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_touch.dart';

/// A group of related rows drawn as one inset card: rounded on the outside
/// only, with hairline dividers between rows that stop short of the leading
/// edge.
///
/// This is the shape a phone settings screen has, and the reason is
/// structural rather than decorative — the card says "these belong together",
/// the inset dividers say "and these are the seams inside it". A stack of
/// bare [ListTile]s separated by full-width rules says neither, which is what
/// the app's Settings screen looked like before this existed.
class InsetGroupedList extends StatelessWidget {
  const InsetGroupedList({super.key, required this.children, this.header});

  /// The rows. Usually [AppListRow]s, but anything works — the group only
  /// clips and separates them.
  final List<Widget> children;

  /// Small label above the group. Names what the group is for when the rows
  /// alone don't make it obvious.
  final String? header;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              header!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        // Material, not a DecoratedBox: rows paint their ink splash on the
        // nearest Material ancestor, so a plain colored box above them would
        // swallow every tap ripple in the group.
        Material(
          color: theme.colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    // Inset to clear the icon column, so the divider reads as
                    // a seam inside one card rather than a cut between two.
                    indent: AppSpacing.xxl + AppSpacing.lg,
                    color: theme.colorScheme.outlineVariant,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row of an [InsetGroupedList].
///
/// The icon sits in a filled rounded square rather than floating loose: it
/// gives the row a consistent leading column whatever the glyph, and lets a
/// destructive or category color be carried by a shape instead of by tinting
/// the label text.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.destructive = false,
    this.showChevron,
  });

  final IconData icon;
  final String label;

  /// Secondary text at the trailing edge — the row's current setting, a
  /// count, a status.
  final String? value;

  final VoidCallback? onTap;

  /// Replaces the default chevron. A switch, a spinner, nothing at all.
  final Widget? trailing;

  /// Overrides the icon tile's color. Ignored when [destructive] is set.
  final Color? iconColor;

  /// Colors the row as a destructive action. The label goes red too, because
  /// a red icon alone next to black text reads as a category, not a warning.
  final bool destructive;

  /// Whether to show the trailing chevron. Defaults to "yes if this row
  /// navigates" — a tappable row that acts in place (a toggle, Log out)
  /// promises a screen it never opens if it wears one.
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = destructive
        ? theme.colorScheme.error
        : (iconColor ?? theme.colorScheme.primary);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouch.minTarget + 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.xl + AppSpacing.xs,
                height: AppSpacing.xl + AppSpacing.xs,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              // Label and value share the row's remaining width, both
              // flexible: an `Expanded` label with a fixed-width value beside
              // it overflows the moment the value is something long and real,
              // like the account's own email address.
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: destructive ? theme.colorScheme.error : null,
                        ),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          value!,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
              // The chevron is what makes a row read as "this opens
              // something" rather than as a label with a value beside it.
              if (trailing == null &&
                  (showChevron ?? (onTap != null && !destructive)))
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.xs,
                  ),
                  child: Icon(
                    // Mirrors in RTL.
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
