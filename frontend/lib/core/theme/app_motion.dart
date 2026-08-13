import 'package:flutter/material.dart';

/// Shared motion durations and curves for this app's animations. Formalizes
/// the convention already in use by [VideoLikeButton]'s like-pop and
/// [VideoCard]'s hover transition, rather than inventing a new one — new
/// animations should reference these constants instead of picking their own
/// duration literal.
abstract final class AppMotion {
  /// 120ms — micro feedback for a single control (e.g. the like-button
  /// scale pop, icon/text swap on toggle).
  static const Duration fast = Duration(milliseconds: 120);

  /// 200ms — hover/state transitions on a component (e.g. a card's hover
  /// elevation/scale/border change).
  static const Duration base = Duration(milliseconds: 200);

  /// 320ms — larger transitions (e.g. section reveals, larger layout
  /// changes).
  static const Duration slow = Duration(milliseconds: 320);

  /// 1200ms — a single half-cycle of a continuously looping animation (e.g.
  /// [SkeletonBox]'s opacity pulse, played with `reverse: true`). Distinct
  /// from the one-shot durations above, which describe a transition that
  /// starts and settles rather than repeats indefinitely.
  static const Duration loop = Duration(milliseconds: 1200);

  /// Curve for animations that enter/appear or grow.
  static const Curve enter = Curves.easeOut;

  /// Curve for animations that exit/disappear or shrink.
  static const Curve exit = Curves.easeIn;
}
