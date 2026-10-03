import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.forestGreen,
      onPrimary: AppColors.pureWhite,
      primaryContainer: AppColors.mintBackground,
      onPrimaryContainer: AppColors.forestGreen,
      secondary: AppColors.limeAccent,
      onSecondary: AppColors.forestGreenDark,
      surface: AppColors.cardBackground,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.pageBackground,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLight,
      error: AppColors.actionNeededOrange,
      onError: AppColors.pureWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      textTheme: AppTypography.createTextTheme(AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacingThemeExtension.regular(),
        AppMotionThemeExtension.regular(),
      ],
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.limeAccent,
      onPrimary: AppColors.forestGreenDark,
      primaryContainer: AppColors.forestGreenSurface,
      onPrimaryContainer: AppColors.mintPillText,
      secondary: AppColors.mintPillText,
      onSecondary: AppColors.forestGreenDark,
      surface: AppColors.forestGreenDark,
      onSurface: AppColors.pureWhite,
      surfaceContainerHighest: AppColors.forestGreenSurface,
      outline: AppColors.forestGreenSurface,
      outlineVariant: AppColors.forestGreenLight,
      error: AppColors.actionNeededOrange,
      onError: AppColors.pureWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.forestGreenDark,
      textTheme: AppTypography.createTextTheme(AppColors.pureWhite),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.forestGreenDark,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.forestGreenSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.forestGreenLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.forestGreenLight,
        thickness: 1,
        space: 1,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacingThemeExtension.regular(),
        AppMotionThemeExtension.regular(),
      ],
    );
  }
}
