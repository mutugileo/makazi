import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.teal700,
      onPrimary: AppColors.pureWhite,
      primaryContainer: AppColors.teal50,
      onPrimaryContainer: AppColors.teal700,
      secondary: AppColors.slate700,
      onSecondary: AppColors.pureWhite,
      surface: AppColors.pureWhite,
      onSurface: AppColors.slate900,
      surfaceContainerHighest: AppColors.slate100,
      outline: AppColors.slate200,
      outlineVariant: AppColors.slate100,
      error: AppColors.rose600,
      onError: AppColors.pureWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.slate50,
      textTheme: AppTypography.createTextTheme(AppColors.slate900),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.slate200),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate200,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.pureWhite,
        indicatorColor: AppColors.teal100,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.teal700);
          }
          return const IconThemeData(color: AppColors.slate500);
        }),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacingThemeExtension.regular(),
        AppMotionThemeExtension.regular(),
      ],
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.teal600,
      onPrimary: AppColors.pureWhite,
      primaryContainer: AppColors.slate800,
      onPrimaryContainer: AppColors.teal100,
      secondary: AppColors.slate300,
      onSecondary: AppColors.slate950,
      surface: AppColors.slate900,
      onSurface: AppColors.slate100,
      surfaceContainerHighest: AppColors.slate800,
      outline: AppColors.slate700,
      outlineVariant: AppColors.slate800,
      error: AppColors.rose600,
      onError: AppColors.pureWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.slate950,
      textTheme: AppTypography.createTextTheme(AppColors.slate100),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate900,
        foregroundColor: AppColors.slate100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.slate900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.slate800),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate800,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.slate900,
        indicatorColor: AppColors.slate800,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.teal600);
          }
          return const IconThemeData(color: AppColors.slate400);
        }),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacingThemeExtension.regular(),
        AppMotionThemeExtension.regular(),
      ],
    );
  }
}
