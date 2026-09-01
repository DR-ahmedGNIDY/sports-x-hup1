import 'package:flutter/material.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/feed_item.dart';
import 'feed_layout.dart';

/// A feed post's media — a photo, or a video's thumbnail with a play
/// affordance over it.
///
/// Sized purely by aspect ratio off the card's width (no fixed pixel
/// width or height anywhere in this subtree), so it shrinks and grows in
/// lockstep with the card, the window, and browser zoom.
///
/// The ratio is the media's own: the feed API carries no width/height, so
/// this resolves the decoded image's intrinsic dimensions and clamps them
/// to [FeedLayout.minMediaAspect]..[FeedLayout.maxMediaAspect]. That's the
/// difference between a portrait post rendering as a sensible tall card
/// and being cropped to a 16:9 slice of itself. Resolution goes through
/// the same [ImageProvider] the [Image] widget below uses, so it's one
/// cache entry and one download, and it settles the ratio once per image
/// rather than per frame.
class FeedMedia extends StatefulWidget {
  const FeedMedia({super.key, required this.item, required this.onPlayVideo});

  final FeedItem item;
  final VoidCallback onPlayVideo;

  @override
  State<FeedMedia> createState() => _FeedMediaState();
}

class _FeedMediaState extends State<FeedMedia> {
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _intrinsicAspect;
  bool _failed = false;

  bool get _isVideo => widget.item.kind == FeedItemKind.video;

  /// The still image to paint: a video's thumbnail, or the photo itself.
  String? get _imageUrl => _isVideo ? widget.item.thumbnailUrl : widget.item.secureUrl;

  double get _aspect {
    final aspect = _intrinsicAspect;
    if (aspect == null || !aspect.isFinite || aspect <= 0) {
      return FeedLayout.defaultMediaAspect;
    }
    return aspect.clamp(FeedLayout.minMediaAspect, FeedLayout.maxMediaAspect);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveIntrinsicAspect();
  }

  @override
  void didUpdateWidget(covariant FeedMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ListView.builder recycles elements across posts — a new URL means
    // the previously measured ratio no longer describes this media.
    if (oldWidget.item.secureUrl != widget.item.secureUrl ||
        oldWidget.item.thumbnailUrl != widget.item.thumbnailUrl) {
      _intrinsicAspect = null;
      _failed = false;
      _resolveIntrinsicAspect();
    }
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  void _detachListener() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _listener = null;
    _stream = null;
  }

  void _resolveIntrinsicAspect() {
    final url = _imageUrl;
    if (url == null) return;
    // Cached like every other remote image, but deliberately not resized:
    // this provider exists to read the photo's *intrinsic* dimensions, and
    // a ResizeImage would report the resized ones.
    final provider = appImageProvider(url, context: context);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    // Same image as last time (a plain rebuild) — keep the live listener
    // rather than tearing it down and re-resolving.
    if (_stream?.key == stream.key) return;
    _detachListener();
    _provider = provider;
    _stream = stream;
    _listener = ImageStreamListener(_onImage, onError: _onImageError);
    stream.addListener(_listener!);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    final aspect = info.image.width / info.image.height;
    // The listener owns this clone of the image handle.
    info.dispose();
    if (!mounted || _intrinsicAspect == aspect) return;
    setState(() => _intrinsicAspect = aspect);
  }

  void _onImageError(Object error, StackTrace? stackTrace) {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = AspectRatio(aspectRatio: _aspect, child: _buildSurface(context));
    if (!_isVideo) return media;

    return Semantics(
      button: true,
      label: l10n.feedPlayVideoLabel,
      // MouseRegion so the thumbnail reads as clickable on Desktop web —
      // a bare GestureDetector leaves the default arrow cursor.
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onPlayVideo, child: media),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    final colors = context.profileColors;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.bg),
        if (!_failed && _provider != null)
          Image(
            image: _provider!,
            // Cover, never fill: the media always covers the card's width
            // at the ratio above with no distortion, and the clamp keeps
            // the cropped-away amount small.
            fit: BoxFit.cover,
            // A quiet fade instead of the image snapping in — one rebuild
            // when the first frame arrives, not a running animation.
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppMotion.base,
                curve: AppMotion.enter,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) => const _MediaUnavailable(),
          )
        else
          const _MediaUnavailable(),
        if (_isVideo) ...[
          // A soft radial scrim rather than a flat veil: dark enough at
          // the center for the play button to read against a bright
          // thumbnail, without dulling the edges of the frame.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(radius: 0.9, colors: [Color(0x59000000), Color(0x1A000000)]),
            ),
          ),
          const Center(child: _PlayBadge()),
        ],
      ],
    );
  }
}

/// Shown when the media can't be loaded — a quiet placeholder inside the
/// same ratio box, so a broken image doesn't collapse the card's layout.
class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = context.profileColors;
    return ColoredBox(
      color: colors.bg,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: colors.textMuted.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// The play affordance over a video thumbnail. Sized in logical pixels on
/// purpose — it's a control, and controls shouldn't scale with the
/// picture behind them any more than the card's text does.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.black.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.85), width: 2),
      ),
      child: const Icon(Icons.play_arrow_rounded, color: AppColors.white, size: 34),
    );
  }
}
