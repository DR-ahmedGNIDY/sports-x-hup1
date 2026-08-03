import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central theme definitions. Screens must consume colors/text styles via
/// `Theme.of(context)`, never by hardcoding hex values inline.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

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
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.slate : AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.slate : AppColors.offWhite,
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
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.slate : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.slate : AppColors.greyLight,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.slate : AppColors.offWhite,
        thickness: 1,
      ),
    );
  }
}
