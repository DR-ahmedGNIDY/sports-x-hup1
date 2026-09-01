// The test font is a grid of identical one-em boxes, so any assertion about
// whether text fits its box is really an assertion about that font. Tajawal
// is what the app ships; loading it is the difference between measuring the
// layout and measuring the harness.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_text_styles.dart';

const _files = <String>[
  'assets/fonts/Tajawal-Regular.ttf',
  'assets/fonts/Tajawal-Medium.ttf',
  'assets/fonts/Tajawal-Bold.ttf',
];

/// Call from `setUpAll` in any test that measures text.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader(AppTextStyles.fontFamily);
  for (final file in _files) {
    loader.addFont(
      File(file).readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
    );
  }
  await loader.load();
}
