import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../application/catalog_providers.dart';
import '../../domain/entities/store_banner.dart';
import '../store_paths.dart';

/// How long each slide holds before the next one. Long enough to read a
/// headline burnt into the artwork, which is the whole point of a hero.
const Duration _slideDuration = Duration(seconds: 6);

/// The storefront hero: the merchant's banners, one at a time.
///
/// Carries no overlay text of its own — the message lives in the artwork,
/// the way the reference storefront does it, because a headline laid over a
/// photograph of a garment competes with the garment.
class StoreHero extends ConsumerStatefulWidget {
  const StoreHero({super.key});

  @override
  ConsumerState<StoreHero> createState() => _StoreHeroState();
}

class _StoreHeroState extends ConsumerState<StoreHero> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  /// Set the first time the customer swipes or taps a dot. An auto-advancing
  /// carousel that keeps moving under someone who has taken control of it is
  /// how a hero loses the slide they were reading.
  bool _userTookOver = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer(int slideCount) {
    _timer?.cancel();
    if (_userTookOver || slideCount < 2) return;
    // Honours the platform's reduce-motion setting, like SkeletonBox: a
    // carousel that advances on its own is exactly the motion that setting
    // exists to stop.
    if (MediaQuery.of(context).disableAnimations) return;

    _timer = Timer.periodic(_slideDuration, (_) {
      if (!mounted) return;
      _controller.animateToPage(
        (_index + 1) % slideCount,
        duration: AppMotion.slow,
        curve: AppMotion.enter,
      );
    });
  }

  void _takeOver() {
    if (_userTookOver) return;
    _userTookOver = true;
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(storeBannersProvider);
    final isDesktop = AppBreakpoints.isDesktop(context);
    final height = isDesktop ? 560.0 : 460.0;

    return banners.when(
      data: (items) {
        if (items.isEmpty) return _EmptyHero(height: height);

        // Rebuilt whenever the slide count changes — a banner added or
        // deactivated should not leave the timer pointing past the end.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _timer == null) _restartTimer(items.length);
        });

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // A pointer landing on the hero is what marks it taken over.
              // `onPageChanged` cannot be used for this — it fires for the
              // timer's own advances too, so the carousel would stop itself
              // on the first tick.
              Listener(
                onPointerDown: (_) => _takeOver(),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: items.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => _Slide(
                    banner: items[index],
                    isDesktop: isDesktop,
                    onTap: () => _open(items[index]),
                  ),
                ),
              ),
              if (items.length > 1)
                PositionedDirectional(
                  bottom: 16,
                  start: 0,
                  end: 0,
                  child: _Dots(
                    count: items.length,
                    index: _index,
                    onSelect: (index) {
                      _takeOver();
                      _controller.animateToPage(
                        index,
                        duration: AppMotion.base,
                        curve: AppMotion.enter,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      // Both non-data states render the same band the hero occupies, so the
      // page below it never jumps once the banners arrive.
      loading: () => _EmptyHero(height: height),
      error: (_, _) => _EmptyHero(height: height),
    );
  }

  void _open(StoreBanner banner) {
    final path = banner.linkPath;
    if (path == null || path.isEmpty) return;
    // The stored path is relative to the store's own root, so it is
    // prefixed here rather than at the merchant's keyboard.
    context.go('${StorePaths.prefix}$path');
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.banner,
    required this.isDesktop,
    required this.onTap,
  });

  final StoreBanner banner;
  final bool isDesktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final alt = banner.alt(isArabic);
    final hasLink = banner.linkPath != null && banner.linkPath!.isNotEmpty;

    // Desktop shows the merchant's artwork in full — cropping the one image
    // a merchant picked to represent their storefront is worse than letting
    // it sit on the band colour either side of it. Mobile stays `cover`: at
    // phone widths there is no room either side to letterbox into.
    final image = Container(
      color: Theme.of(context).brightness == Brightness.light
          ? StoreTheme.surfaceAlt
          : StoreTheme.darkSurfaceAlt,
      child: CachedNetworkImage(
        imageUrl: banner.imageFor(isDesktop: isDesktop),
        fit: isDesktop ? BoxFit.contain : BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => _band(context),
        // The description stands in for the picture when it fails, which is
        // the case a decorative-only hero has nothing to say in.
        errorWidget: (_, _, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              alt ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );

    // Only labelled when there is something to say. An image with an empty
    // label is worse than an unlabelled one: a screen reader announces it
    // and conveys nothing.
    final described = alt == null || alt.isEmpty
        ? ExcludeSemantics(child: image)
        : Semantics(image: true, label: alt, child: image);

    if (!hasLink) return described;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: described),
    );
  }

  Widget _band(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.light
        ? StoreTheme.surfaceAlt
        : StoreTheme.darkSurfaceAlt,
    child: const SizedBox.expand(),
  );
}

/// The empty band shown while the banners load, when they fail, and when the
/// merchant has not uploaded any. Deliberately blank rather than carrying a
/// placeholder headline, which would have to be written, translated, and
/// then deleted.
class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: Theme.of(context).brightness == Brightness.light
            ? StoreTheme.surfaceAlt
            : StoreTheme.darkSurfaceAlt,
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.onSelect,
  });

  final int count;
  final int index;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == index,
            label: 'Slide ${i + 1} of $count',
            child: InkWell(
              onTap: () => onSelect(i),
              // The dot itself is 8px; the tap target around it is not.
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                  width: i == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    // White with a shadow, because a hero sits on the
                    // merchant's photograph and the dots cannot assume
                    // whether it is light or dark underneath.
                    color: i == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
