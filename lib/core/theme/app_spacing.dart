import 'dart:ui';
import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;
}

@immutable
class AppSpacingThemeExtension
    extends ThemeExtension<AppSpacingThemeExtension> {
  const AppSpacingThemeExtension({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  const AppSpacingThemeExtension.regular()
    : xxs = AppSpacing.xxs,
      xs = AppSpacing.xs,
      sm = AppSpacing.sm,
      md = AppSpacing.md,
      lg = AppSpacing.lg,
      xl = AppSpacing.xl,
      xxl = AppSpacing.xxl,
      radiusSm = AppSpacing.radiusSm,
      radiusMd = AppSpacing.radiusMd,
      radiusLg = AppSpacing.radiusLg;

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  @override
  AppSpacingThemeExtension copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return AppSpacingThemeExtension(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  ThemeExtension<AppSpacingThemeExtension> lerp(
    covariant ThemeExtension<AppSpacingThemeExtension>? other,
    double t,
  ) {
    if (other is! AppSpacingThemeExtension) {
      return this;
    }
    return AppSpacingThemeExtension(
      xxs: lerpDouble(xxs, other.xxs, t) ?? xxs,
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
    );
  }
}
