import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// The app's one way to present a bottom sheet.
///
/// Before this, seven call sites each opened `showModalBottomSheet` with
/// their own arguments, and they disagreed: some had a drag handle and some
/// didn't, some were scroll-controlled and some clipped their own content,
/// some rounded their corners and some were square, and none of them reserved
/// space for the home indicator. Those inconsistencies are individually
/// invisible and collectively the difference between a set of screens and an
/// app.
///
/// [show] takes the same builder a raw sheet would; everything the sheet
/// needs to behave correctly is decided here.
abstract final class AppSheet {
  /// Presents [builder] as a modal sheet.
  ///
  /// [title] adds a header row above the content; omit it for a sheet whose
  /// content already says what it is. [fullHeight] lets a sheet that will grow
  /// — a comment list, a form with a keyboard — start tall instead of resizing
  /// under the user.
  ///
  /// [backgroundColor] is the one thing a caller may still choose: the feed
  /// and video sheets sit on the Player Profile's darker surface, which is a
  /// deliberate feature palette rather than the drift this class exists to
  /// remove. Everything else — shape, handle, scroll control, safe area,
  /// keyboard inset — is decided here.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool fullHeight = false,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: backgroundColor,
      // Always: a sheet that can't grow past half the screen traps its own
      // content behind an inner scrollbar the moment a keyboard appears.
      isScrollControlled: true,
      showDragHandle: true,
      // Keeps the sheet clear of the status bar at the top and the home
      // indicator at the bottom — the reason several of the old sheets had
      // their last button half under the gesture bar.
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => _SheetBody(
        title: title,
        fullHeight: fullHeight,
        child: builder(sheetContext),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.fullHeight,
    required this.child,
  });

  final String? title;
  final bool fullHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final body = Column(
      mainAxisSize: fullHeight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Text(title!, style: theme.textTheme.titleMedium),
          ),
        Flexible(child: child),
      ],
    );

    return Padding(
      // Lifts the sheet above the keyboard instead of letting it cover the
      // field the sheet exists to fill in.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: fullHeight
          ? FractionallySizedBox(heightFactor: 0.92, child: body)
          : body,
    );
  }
}
