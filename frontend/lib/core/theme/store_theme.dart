import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// The storefront's own look, separate from [AppTheme].
///
/// Sport X Hub is a brand-blue product app; a clothing store is not. The
/// reference storefronts in this category are near-monochrome on purpose —
/// every colour on the page comes from the product photography, and any
/// brand colour competing with it makes the garments look worse. So this is
/// a black-and-white theme with the brand blue demoted to a link/focus
/// accent, not a paint.
///
/// It lives beside [AppTheme] rather than replacing it because the two apps
/// share one Flutter package and one `core/` — only the entrypoint differs.
abstract final class StoreTheme {
  // Near-black rather than pure black: #000 against white vibrates on an
  // LCD and makes long text harder to read.
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkMuted = Color(0xFF6B6B6B);
  static const Color hairline = Color(0xFFE5E5E5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF6F6F6);

  /// Sale prices and the "New" badge. Both read as red on the reference
  /// storefront, and a discount that does not look urgent is not doing its
  /// job.
  static const Color sale = Color(0xFFD32F2F);
  static const Color badgeNew = Color(0xFF2E7D32);

  /// Dark counterparts. The store is a light-first design — clothing
  /// photography is shot on light backgrounds — but the viewer's system
  /// preference still has to be honoured rather than ignored.
  static const Color darkInk = Color(0xFFF5F5F5);
  static const Color darkInkMuted = Color(0xFF9E9E9E);
  static const Color darkHairline = Color(0xFF2A2A2A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceAlt = Color(0xFF1C1C1C);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final foreground = isLight ? ink : darkInk;
    final background = isLight ? surface : darkSurface;
    final muted = isLight ? inkMuted : darkInkMuted;
    final line = isLight ? hairline : darkHairline;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brandBlue,
          brightness: brightness,
        ).copyWith(
          surface: background,
          onSurface: foreground,
          // The primary action on a storefront is "Add to bag", and it is
          // black — the product is the colour, not the button.
          primary: foreground,
          onPrimary: background,
          outline: line,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      // The reference storefront's header is a thin white bar with a single
      // hairline under it — no elevation, no tint on scroll.
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      textTheme: _textTheme(foreground, muted),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: foreground,
          foregroundColor: background,
          // Nearly square. A pill-shaped button reads as a consumer app; a
          // near-rectangular one reads as retail.
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxs)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: line),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxs)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? surfaceAlt : darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxs)),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxs)),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xxs)),
          borderSide: BorderSide(color: foreground, width: 1.4),
        ),
      ),
      // Product tiles carry no card chrome at all on the reference site —
      // no border, no fill, no shadow. The photograph is the card.
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxs)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// Retail typography: small, wide-tracked uppercase for structure, and
  /// quiet body text. Section headings on the reference site are noticeably
  /// lighter and smaller than a typical app's — the products carry the page.
  static TextTheme _textTheme(Color foreground, Color muted) => TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.6,
      color: foreground,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: foreground,
    ),
    // The product name on a tile.
    bodyMedium: TextStyle(fontSize: 13, height: 1.5, color: foreground),
    bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
    labelLarge: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: foreground,
    ),
    // Nav items and badges.
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.9,
      color: muted,
    ),
  );
}
