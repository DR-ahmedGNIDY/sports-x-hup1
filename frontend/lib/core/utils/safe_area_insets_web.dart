import 'dart:js_interop';

import 'package:flutter/widgets.dart';

/// The probe installed by the inline script in `web/index.html`. Returns the
/// live `env(safe-area-inset-*)` values as `"top,right,bottom,left"` in CSS
/// pixels — a string rather than an object so this binding stays a single
/// external declaration with no interop type plumbing.
@JS('sxhSafeAreaInsets')
external JSFunction? get _sxhSafeAreaInsets;

/// Reads the browser's safe-area insets. Falls back to [EdgeInsets.zero] on
/// anything unexpected — an `index.html` served without the probe (an older
/// cached shell, a test harness), a browser that doesn't support `env()`, or
/// a malformed value. A missing inset only costs the app its edge padding;
/// throwing here would cost it every frame.
EdgeInsets readSafeAreaInsets() {
  final probe = _sxhSafeAreaInsets;
  if (probe == null) return EdgeInsets.zero;

  final raw = probe.callAsFunction()?.dartify();
  if (raw is! String) return EdgeInsets.zero;

  final parts = raw.split(',');
  if (parts.length != 4) return EdgeInsets.zero;

  final values = <double>[];
  for (final part in parts) {
    final value = double.tryParse(part);
    if (value == null || !value.isFinite || value < 0) return EdgeInsets.zero;
    values.add(value);
  }

  return EdgeInsets.fromLTRB(values[3], values[0], values[1], values[2]);
}
