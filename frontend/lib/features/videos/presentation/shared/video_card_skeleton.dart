import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/skeleton_box.dart';

/// Loading placeholder shaped like [VideoCard]: a 16:9 thumbnail block over
/// a couple of text-line bars, same corner radius and surface tint. Used
/// wherever a video grid's `.when(loading: ...)` branch swaps a bare
/// spinner for a skeleton that already matches the eventual layout.
class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(aspectRatio: 16 / 9, child: SkeletonBox(borderRadius: BorderRadius.zero)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 90, height: 12),
                const SizedBox(height: 8),
                SkeletonBox(width: 50, height: 12, borderRadius: BorderRadius.circular(AppRadius.xxs)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A `GridView` of [VideoCardSkeleton] tiles, sized with the same
/// [gridDelegate] the real grid uses — so the loading state doesn't jump
/// once data arrives.
class VideoGridSkeleton extends StatelessWidget {
  const VideoGridSkeleton({super.key, required this.gridDelegate, this.itemCount = 6});

  final SliverGridDelegate gridDelegate;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Both of these matter, and their absence was a real bug: this grid
      // always renders *inside* another scroll view (the Skills section, on
      // the Player Profile and the Skills page), so without them it asks for
      // unbounded height and its own scroll offset resolves to NaN. A release
      // build logged `Result of truncating division is NaN` twice on every
      // authenticated route because of it — the loading state is on screen
      // before any data arrives, and the Skills section is mounted in more
      // than one branch at once.
      //
      // The two real grids this stands in for already set both; the skeleton
      // that copies their `gridDelegate` has to copy their scroll behaviour
      // too, or it doesn't stand in for them.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) => const VideoCardSkeleton(),
    );
  }
}
