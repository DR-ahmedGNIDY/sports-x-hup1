// Phase Mobile M6 — the image loading rules.
//
// The app draws ~19 remote images, all of them Cloudinary originals at their
// upload resolution. Two properties matter and neither is visible on screen,
// which is exactly why they are pinned here: the images are cached, and they
// are decoded at the size they are drawn rather than the size they were
// uploaded.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/utils/app_image.dart';

const _url = 'https://example.test/photo.jpg';

Future<ImageProvider> _provider(
  WidgetTester tester, {
  int? decodeWidth,
  double devicePixelRatio = 1.0,
}) async {
  late ImageProvider provider;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(devicePixelRatio: devicePixelRatio),
      child: Builder(
        builder: (context) {
          provider = appImageProvider(
            _url,
            context: context,
            decodeWidth: decodeWidth,
          );
          return const SizedBox();
        },
      ),
    ),
  );
  return provider;
}

void main() {
  testWidgets('every remote image is cached', (tester) async {
    // A bare NetworkImage keeps decoded frames in Flutter's in-memory cache
    // and nothing else, so an avatar re-downloads whenever it is evicted —
    // which, with the shell keeping every tab mounted, happens often.
    final provider = await _provider(tester);
    expect(provider, isA<CachedNetworkImageProvider>());
  });

  testWidgets('a decode width caps the decoded size', (tester) async {
    final provider = await _provider(tester, decodeWidth: 48);

    expect(provider, isA<ResizeImage>());
    expect((provider as ResizeImage).width, 48);
    // The cache still sits underneath the resize, not beside it.
    expect(provider.imageProvider, isA<CachedNetworkImageProvider>());
  });

  testWidgets('the decode width is in logical pixels, not device pixels', (
    tester,
  ) async {
    // A call site says "this avatar is 48 wide" and means logical pixels; on
    // a 3x screen that is 144 real ones. Applying the ratio here is what
    // stops every call site having to remember to.
    final provider =
        await _provider(tester, decodeWidth: 48, devicePixelRatio: 3.0)
            as ResizeImage;

    expect(provider.width, 144);
  });

  testWidgets('no decode width means no resize wrapper at all', (tester) async {
    // The zoomable photo viewer and the feed's intrinsic-size probe both
    // need the real image: a cap would put a ceiling on zoom in one and
    // report the wrong dimensions in the other.
    final provider = await _provider(tester);
    expect(provider, isNot(isA<ResizeImage>()));
  });

  test('the named sizes stay ordered', () {
    expect(AppImageSize.avatarSmall, lessThan(AppImageSize.avatarLarge));
    expect(AppImageSize.avatarLarge, lessThan(AppImageSize.thumbnail));
    expect(AppImageSize.thumbnail, lessThan(AppImageSize.fullWidth));
  });
}
