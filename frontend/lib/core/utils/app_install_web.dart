import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'app_install.dart';

/// Installed by the inline script in `web/index.html`, which has to capture
/// `beforeinstallprompt` before Dart is running — the browser fires it once,
/// early, and it cannot be re-requested.
@JS('sxhCanInstall')
external JSFunction? get _canInstall;

@JS('sxhIsInstalled')
external JSFunction? get _isInstalled;

@JS('sxhPromptInstall')
external JSFunction? get _promptInstall;

bool _callBool(JSFunction? fn) {
  if (fn == null) return false;
  final result = fn.callAsFunction()?.dartify();
  return result is bool && result;
}

InstallOffer resolveInstallOffer() {
  // Running as an installed app already — offering to install it again is
  // the kind of detail that makes software feel like it isn't paying
  // attention.
  if (_callBool(_isInstalled)) return InstallOffer.none;

  if (_callBool(_canInstall)) return InstallOffer.prompt;

  // No captured event. On WebKit that means iOS/iPadOS, where installing is a
  // manual Share-sheet action the app can explain; anywhere else it means a
  // browser that does not install, or one that has not fired the event yet.
  return _isAppleBrowser() ? InstallOffer.instructions : InstallOffer.none;
}

Future<bool> runInstallPrompt() async {
  final fn = _promptInstall;
  if (fn == null) return false;
  final result = fn.callAsFunction();
  if (result.isA<JSPromise>()) {
    final resolved = await (result! as JSPromise).toDart;
    return resolved.dartify() == true;
  }
  return result?.dartify() == true;
}

bool _isAppleBrowser() =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;
