import 'package:flutter/widgets.dart';

import 'safe_area_insets_stub.dart'
    if (dart.library.js_interop) 'safe_area_insets_web.dart';

/// The device's safe-area insets (notch, status bar, home indicator).
///
/// On every platform except web this is already handled for us: the embedder
/// fills `MediaQuery.padding` and [SafeArea] just works. Flutter Web does
/// not — `MediaQuery.padding` is permanently zero there, so with
/// `viewport-fit=cover` set in `web/index.html` the app paints edge to edge
/// and its bottom navigation ends up underneath the iPhone home indicator.
///
/// [applyWebSafeArea] closes that gap by reading the CSS `env(safe-area-inset-*)`
/// values through the probe installed in `web/index.html` and injecting them
/// into the inherited [MediaQueryData], after which [SafeArea] and
/// `MediaQuery.paddingOf` behave on web exactly as they do on iOS/Android.
///
/// A no-op off the web, where the platform values are already correct and
/// must not be overwritten.
Widget applyWebSafeArea({required BuildContext context, required Widget child}) {
  // Read before the early return, and unconditionally: `MediaQuery.of`
  // registers this build as a dependency of the inherited MediaQuery, which
  // is what schedules a rebuild when the window's metrics change. Returning
  // early on zero insets *before* reading it meant the dependency was never
  // registered on a surface that starts with no insets — so rotating the
  // device into an orientation that does have them never re-read the probe.
  final media = MediaQuery.of(context);

  final insets = readSafeAreaInsets();
  if (insets == EdgeInsets.zero) return child;

  return MediaQuery(
    // `padding` is what SafeArea consumes; `viewPadding` is the same value
    // ignoring the keyboard, and staying consistent between the two keeps
    // widgets that read either one in agreement.
    data: media.copyWith(
      padding: media.padding + insets,
      viewPadding: media.viewPadding + insets,
    ),
    child: child,
  );
}
