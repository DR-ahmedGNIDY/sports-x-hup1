import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';
import 'app_touch.dart';
import 'profile_colors.dart';

/// Central theme definitions. Screens must consume colors/text styles via
/// `Theme.of(context)`, never by hardcoding hex values inline.
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
        style: OutlinedButton.styleFrom(minimumSize: minimumSize),
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

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: brightness,
      primary: AppColors.brandBlue,
      secondary: AppColors.brandBlueLight,
      error: AppColors.error,
      surface: isDark ? AppColors.charcoal : AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.black : AppColors.offWhite,
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
          color: isDark ? AppColors.greyLight : AppColors.grey,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.white,
        foregroundColor: colorScheme.onSurface,
        elevation: AppElevation.flat.value,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.slate : AppColors.white,
        // A real (if subtle) elevation instead of a flat outline. Dark mode
        // leans on a faint, lighter-surface glow rather than a literal drop
        // shadow (black-on-black doesn't read); light mode uses a
        // conventional soft grey shadow. See AppElevation, which pairs the
        // two so they can't be picked apart from each other again.
        elevation: AppElevation.raised.value,
        shadowColor: AppElevation.raised.shadowColor(brightness),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          // Lighter/optional now that elevation carries the separation.
          side: BorderSide(
            color: isDark
                ? AppColors.slate.withValues(alpha: 0.6)
                : AppColors.offWhite.withValues(alpha: 0.8),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.white,
        selectedIconTheme: IconThemeData(color: AppColors.brandBlue),
        selectedLabelTextStyle: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.brandBlue,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.white,
        indicatorColor: AppColors.brandBlue.withValues(alpha: 0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.slate : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: isDark ? AppColors.slate : AppColors.greyLight,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.slate : AppColors.offWhite,
        thickness: 1,
      ),
      extensions: [isDark ? ProfileColors.dark : ProfileColors.light],
    );
  }
}
