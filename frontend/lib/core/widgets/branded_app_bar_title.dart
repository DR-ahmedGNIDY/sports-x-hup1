import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_logo.dart';

/// The app bar's title, everywhere: the wordmark, and the screen's name
/// beside it when it has one.
///
/// This exists because the same two-line arrangement had been written out
/// by hand in six places at three different logo heights, which is how a
/// header ends up subtly different depending on which screen you arrived
/// from. One widget means the mark is the same size on every screen and
/// stays that way.
///
/// The name ellipsizes rather than pushing the logo out of the row — on a
/// 320px phone with an Arabic title and a back button and an action, the
/// mark is the thing that must survive.
class BrandedAppBarTitle extends StatelessWidget {
  const BrandedAppBarTitle({super.key, this.title, this.titleStyle});

  /// `null` on a screen that shows only the wordmark — Home, and the branch
  /// roots whose name is rendered as a large collapsing title below the bar
  /// instead.
  final String? title;

  final TextStyle? titleStyle;

  /// Alone in the bar, the mark can be its full size.
  static const double _soloHeight = 28;

  /// Sharing the row, it steps down so the name has somewhere to go.
  static const double _pairedHeight = 26;

  @override
  Widget build(BuildContext context) {
    if (title == null) return const AppLogo(height: _soloHeight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(height: _pairedHeight),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle ?? Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
