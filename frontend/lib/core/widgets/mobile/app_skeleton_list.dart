import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../skeleton_box.dart';

/// Card-shaped placeholders for a list that is still loading.
///
/// Replaces the centred spinner these screens used. A spinner in the middle of
/// an empty screen says "wait" and nothing else; placeholders the shape of the
/// rows that are coming say what is coming and how much of it, and the screen
/// doesn't jump when the data lands because the space was already reserved.
/// It is the cheapest thing in this whole effort that makes an app feel fast
/// rather than merely be fast.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 96,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  /// Enough to fill a phone screen. More would be placeholders nobody sees;
  /// fewer leaves the fold half empty, which reads as a short list rather
  /// than a loading one.
  final int itemCount;

  final double itemHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < itemCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonBox(
                height: itemHeight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
        ],
      ),
    );
  }
}
