import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared elevation scale. Formalizes the rule already established by
/// `AppTheme`'s `cardTheme`: light mode separates surfaces with a
/// conventional soft grey shadow, dark mode with a faint lighter-surface
/// glow, because a black drop shadow on a near-black background reads as
/// nothing at all.
///
/// Each level is a Material `elevation` value paired with the shadow color
/// that makes it legible in the given brightness — the two always travel
/// together, which is exactly what kept going wrong when they were picked
/// independently at each call site.
enum AppElevation {
  /// No separation. A surface that belongs to the background — section
  /// wrappers, inline containers distinguished by fill alone.
  flat(0),

  /// The default for content cards: present, but not competing with the
  /// content inside it.
  raised(1),

  /// Lifted above the content plane — FABs, sticky action bars, anything
  /// that stays put while content scrolls under it.
  floating(3),

  /// Above everything: menus, dialogs, bottom sheets.
  overlay(8);

  const AppElevation(this.value);

  /// The Material `elevation` this level maps to.
  final double value;

  /// The shadow color this level needs to be visible in [brightness]. Always
  /// pair it with [value] — an elevation with a mismatched shadow color is
  /// either invisible (dark mode, black shadow) or muddy (light mode, blue
  /// glow).
  Color shadowColor(Brightness brightness) => brightness == Brightness.dark
      ? AppColors.brandBlueLight.withValues(alpha: 0.04 * value + 0.08)
      : AppColors.black.withValues(alpha: 0.04 * value + 0.04);
}
