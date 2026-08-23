import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// The Club Home's news section on Desktop: the feed column beside a
/// secondary column, laid out side by side *inside the page's own scroll*
/// (both children are slivers, so neither column needs a height and the
/// page never nests a second scroll view).
///
/// Handles the direction itself: [SliverCrossAxisGroup] places its first
/// child on the left whatever the ambient [Directionality] is, so in
/// Arabic the primary column would end up on the wrong side. The order is
/// reversed for RTL, which puts the feed on the reading-start side in both
/// languages. The gutter rides on the secondary column as a directional
/// inset, so it stays *between* the two columns either way.
class ClubNewsColumns extends StatelessWidget {
  const ClubNewsColumns({
    super.key,
    required this.feed,
    required this.secondary,
    this.feedFlex = 2,
    this.secondaryFlex = 1,
    this.gutter = AppSpacing.xl,
  });

  /// The feed column — a sliver (see `FeedColumnSliver`).
  final Widget feed;

  /// The supporting column — a sliver.
  final Widget secondary;

  final int feedFlex;
  final int secondaryFlex;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final columns = <Widget>[
      SliverCrossAxisExpanded(flex: feedFlex, sliver: feed),
      SliverCrossAxisExpanded(
        flex: secondaryFlex,
        sliver: SliverPadding(
          padding: EdgeInsetsDirectional.only(start: gutter),
          sliver: secondary,
        ),
      ),
    ];

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SliverCrossAxisGroup(slivers: isRtl ? columns.reversed.toList() : columns);
  }
}
