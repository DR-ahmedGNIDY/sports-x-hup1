import 'app_install_stub.dart'
    if (dart.library.js_interop) 'app_install_web.dart';

/// Whether this build can offer to install itself, and how.
///
/// Installing is a browser concept, so all three of these are `false`/no-op
/// anywhere else — a packaged Android or iOS build is already installed by
/// definition.
enum InstallOffer {
  /// Chromium captured a `beforeinstallprompt` event that can be replayed
  /// from a tap. One tap installs.
  prompt,

  /// Safari on iOS/iPadOS, which fires no such event: installing is a manual
  /// Share → Add to Home Screen. The app can only explain it.
  instructions,

  /// Already installed, or a browser that cannot install at all. Nothing to
  /// offer, and an install row that does nothing is worse than no row.
  none,
}

/// What this session should offer, if anything.
InstallOffer installOffer() => resolveInstallOffer();

/// Replays the captured prompt. Returns whether the app was installed.
///
/// Only meaningful for [InstallOffer.prompt]; the browser requires this to
/// happen inside a user gesture, so it must be called straight from a tap
/// handler and not after an await.
Future<bool> promptInstall() => runInstallPrompt();
