import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// How this app loads a remote image.
///
/// Two things that a bare `NetworkImage` does not do, and that every one of
/// the ~19 call sites needed:
///
/// **It caches.** `NetworkImage` keeps decoded frames in Flutter's in-memory
/// image cache and nothing else, so an avatar re-downloads whenever it is
/// evicted — which, with the shell keeping every tab mounted, happens often.
///
/// **It decodes to the size actually drawn.** The photos here come from
/// Cloudinary at their original upload resolution; a 3000px portrait decoded
/// for a 32px avatar costs roughly 36 MB of memory and the CPU time to
/// produce it, per avatar, to throw away 99% of the pixels. [decodeWidth] is
/// the width the image is painted at, in *logical* pixels — the device pixel
/// ratio is applied here so a call site never has to think about it.
ImageProvider appImageProvider(
  String url, {
  required BuildContext context,
  int? decodeWidth,
}) {
  final provider = CachedNetworkImageProvider(url);
  if (decodeWidth == null) return provider;

  final ratio = MediaQuery.devicePixelRatioOf(context);
  return ResizeImage(provider, width: (decodeWidth * ratio).round());
}

/// Decode widths for the shapes this app draws remote images at. Named
/// rather than sprinkled as numbers, so "how big is an avatar" has one
/// answer and a change to a card's layout has one place to update.
abstract final class AppImageSize {
  /// A small circular avatar in a row, bar or card — 16–24 logical px.
  static const int avatarSmall = 48;

  /// A larger avatar: a profile header, the account sheet.
  static const int avatarLarge = 128;

  /// A thumbnail filling a grid cell or a list row's leading square.
  static const int thumbnail = 320;

  /// Media filling the width of a phone screen — a feed card, a profile
  /// hero.
  static const int fullWidth = 800;
}
