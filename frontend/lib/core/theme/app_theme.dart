import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';
import 'app_touch.dart';
import 'profile_colors.dart';

/// Central theme definitions. Screens must consume colors/text styles via
/// `Theme.of(context)`, never by hardcoding hex values inline.
///
/// The SXH identity is monochrome: the accent is ink — black on the light
/// theme, white on the dark one — so the scheme is written out by hand
/// rather than seeded, since a seed always brings a hue of its own.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// [base] re-typed for a phone-sized viewport — see the compact scale in
  /// [AppTextStyles]. Applied by `main.dart` below [AppBreakpoints.desktop]
  /// rather than baked into [light]/[dark], because the two presentation
  /// trees genuinely want different type: the same 14px body that reads
  /// correctly in a desktop browser is undersized in a hand.
  ///
  /// Color, shape and elevation are identical across both layouts by design
  /// — a card is the same card on either. What also changes here is the
  /// minimum height of the text/outlined buttons: Material sizes those at 40,
  /// which is below [AppTouch.minTarget] and reads as a mis-tap rather than
  /// as a small button once a fingertip rather than a cursor is doing the
  /// aiming. Filled buttons already clear it through their own padding.
  static ThemeData compact(ThemeData base) {
    final text = base.textTheme;
    const minimumSize = Size(64, AppTouch.minTarget);

    return base.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minimumSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize,
        ).merge(base.outlinedButtonTheme.style),
      ),
      textTheme: text.copyWith(
        displayLarge: AppTextStyles.compactDisplayLarge.copyWith(
          color: text.displayLarge?.color,
        ),
        headlineSmall: AppTextStyles.compactHeadline.copyWith(
          color: text.headlineSmall?.color,
        ),
        titleMedium: AppTextStyles.compactTitle.copyWith(
          color: text.titleMedium?.color,
        ),
        bodyMedium: AppTextStyles.compactBody.copyWith(
          color: text.bodyMedium?.color,
        ),
        bodyLarge: AppTextStyles.compactBodyStrong.copyWith(
          color: text.bodyLarge?.color,
        ),
        bodySmall: AppTextStyles.compactCaption.copyWith(
          color: text.bodySmall?.color,
        ),
      ),
    );
  }

  static ColorScheme _scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final ink = isDark ? AppColors.white : AppColors.black;
    final paper = isDark ? AppColors.black : AppColors.white;

    return ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: paper,
      primaryContainer: isDark ? AppColors.graphite : AppColors.mist,
      onPrimaryContainer: ink,
      secondary: isDark ? AppColors.greyLight : AppColors.grey,
      onSecondary: paper,
      secondaryContainer: isDark ? AppColors.slate : AppColors.mist,
      onSecondaryContainer: ink,
      tertiary: isDark ? AppColors.greyLight : AppColors.grey,
      onTertiary: paper,
      error: AppColors.error,
      onError: AppColors.white,
      surface: isDark ? AppColors.charcoal : AppColors.white,
      onSurface: isDark ? const Color(0xFFFAFAFA) : AppColors.black,
      onSurfaceVariant: isDark ? AppColors.greyLight : AppColors.grey,
      surfaceContainerLowest: isDark ? AppColors.black : AppColors.white,
      surfaceContainerLow: isDark ? const Color(0xFF111111) : AppColors.offWhite,
      surfaceContainer: isDark ? AppColors.charcoal : AppColors.mist,
      surfaceContainerHigh: isDark ? AppColors.slate : AppColors.mist,
      surfaceContainerHighest: isDark ? AppColors.graphite : AppColors.silver,
      outline: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCFCFD3),
      outlineVariant: isDark ? AppColors.graphite : AppColors.silver,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.white : AppColors.black,
      onInverseSurface: isDark ? AppColors.black : AppColors.white,
      inversePrimary: paper,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _scheme(brightness);
    final border = colorScheme.outlineVariant;

    // Shared by [ElevatedButton] and [FilledButton] so the app's primary
    // action looks the same whichever widget a screen reached for: solid ink
    // with paper-colored text.
    final primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.black : AppColors.offWhite,
      canvasColor: isDark ? AppColors.black : AppColors.offWhite,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineSmall: AppTextStyles.headline.copyWith(
          color: colorScheme.onSurface,
        ),
        titleMedium: AppTextStyles.title.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyMedium: AppTextStyles.body.copyWith(color: colorScheme.onSurface),
        bodyLarge: AppTextStyles.bodyStrong.copyWith(
          color: colorScheme.onSurface,
        ),
        bodySmall: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        foregroundColor: colorScheme.onSurface,
        elevation: AppElevation.flat.value,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        // Light mode separates cards with a soft grey shadow; on black a
        // shadow reads as nothing, so dark mode relies on the hairline.
        elevation: isDark ? 0 : AppElevation.raised.value,
        shadowColor: AppElevation.raised.shadowColor(brightness),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: AppTextStyles.bodyStrong.copyWith(
          color: colorScheme.primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: colorScheme.primary,
        iconColor: colorScheme.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      // The app's actual primary button is FilledButton — most forms use it —
      // so it is themed identically to ElevatedButton.
      filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.slate : AppColors.mist,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      extensions: [isDark ? ProfileColors.dark : ProfileColors.light],
    );
  }
}
