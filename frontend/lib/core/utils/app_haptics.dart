import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The app's haptic vocabulary.
///
/// Four intensities, each meaning one thing, so a buzz is information rather
/// than noise. Calling `HapticFeedback` directly at each site is how an app
/// ends up vibrating at three different strengths for the same class of
/// event.
///
/// Every call is a no-op on the web, where the vibration API is either
/// missing or gated behind a user gesture the framework can't guarantee — and
/// a failed platform call in a tap handler is worse than no feedback. Mobile
/// builds of this same code get the real thing, which is the point of keeping
/// the calls in the widgets rather than behind a platform fork.
abstract final class AppHaptics {
  /// Moving between peers: switching tabs, changing a segmented control.
  /// The lightest of the four — this fires often, and anything stronger
  /// turns routine navigation into a series of thuds.
  static Future<void> selection() => _run(HapticFeedback.selectionClick);

  /// A small state change the user caused: liking, saving, toggling.
  static Future<void> light() => _run(HapticFeedback.lightImpact);

  /// Something completed: a form saved, an upload finished.
  static Future<void> success() => _run(HapticFeedback.mediumImpact);

  /// Something failed, or was refused. The one intensity that should make
  /// someone look at the screen.
  static Future<void> error() => _run(HapticFeedback.heavyImpact);

  static Future<void> _run(Future<void> Function() feedback) async {
    if (kIsWeb) return;
    try {
      await feedback();
    } on PlatformException {
      // A device with no haptic engine, or one that refuses the call. Losing
      // the buzz must never lose the tap that asked for it.
    }
  }
}
