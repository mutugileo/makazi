import 'package:flutter/material.dart';
import '../billing/billing_models.dart';
import 'app_colors.dart';

/// The company's brand colours, from the theme set in MakaziSuperAdmin.
///
/// Makazi's own palette is the fallback: sign-in and anything shown before a
/// company is known use it. Read with `context.brand`.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.primary,
    required this.onPrimary,
    required this.button,
    required this.onButton,
    required this.progress,
    required this.ink,
    required this.link,
    required this.tint,
  });

  factory BrandColors.fromTheme(CompanyTheme theme) {
    final primary = theme.primaryColor;
    // Makazi Forest keeps Makazi's own link and tint shades exactly.
    if (primary == AppColors.forestGreen) {
      return makazi.copyWith(
        button: theme.buttonColor,
        onButton: theme.onButtonColor,
        progress: theme.progressColor,
      );
    }
    final ink = readableOnLight(primary);
    return BrandColors(
      primary: primary,
      onPrimary: theme.onPrimaryColor,
      button: theme.buttonColor,
      onButton: theme.onButtonColor,
      progress: theme.progressColor,
      ink: ink,
      link: ink,
      tint: Color.alphaBlend(
        primary.withValues(alpha: 0.12),
        AppColors.cardBackground,
      ),
    );
  }

  /// Makazi forest with lime calls to action.
  static const BrandColors makazi = BrandColors(
    primary: AppColors.forestGreen,
    onPrimary: AppColors.pureWhite,
    button: AppColors.limeAccent,
    onButton: AppColors.forestGreenDark,
    progress: AppColors.limeAccent,
    ink: AppColors.forestGreen,
    link: AppColors.mintAccent,
    tint: AppColors.mintBackground,
  );

  /// Header, selected states and sent message bubbles.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Main call-to-action buttons (Pay now, New request, Send).
  final Color button;

  /// Text and icons on [button].
  final Color onButton;

  /// Rent progress bar fill.
  final Color progress;

  /// Brand-coloured headings, icons and dark snackbars on light screens.
  /// [primary], darkened until it reads at 4.5:1 on white.
  final Color ink;

  /// Links and small brand-coloured text on light screens.
  final Color link;

  /// Light brand background behind icons and highlighted rows.
  final Color tint;

  /// [color], darkened until white text on it (and it on white) reaches
  /// 4.5:1 contrast. Light brand colours such as sky blue otherwise can't be
  /// read as text on the app's light screens.
  static Color readableOnLight(Color color) {
    var hsl = HSLColor.fromColor(color);
    var result = color;
    // Contrast with white is 4.5:1 once relative luminance is at most 0.183.
    while (result.computeLuminance() > 0.183 && hsl.lightness > 0) {
      hsl = hsl.withLightness((hsl.lightness - 0.02).clamp(0.0, 1.0));
      result = hsl.toColor();
    }
    return result;
  }

  @override
  BrandColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? button,
    Color? onButton,
    Color? progress,
    Color? ink,
    Color? link,
    Color? tint,
  }) => BrandColors(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    button: button ?? this.button,
    onButton: onButton ?? this.onButton,
    progress: progress ?? this.progress,
    ink: ink ?? this.ink,
    link: link ?? this.link,
    tint: tint ?? this.tint,
  );

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      button: Color.lerp(button, other.button, t)!,
      onButton: Color.lerp(onButton, other.onButton, t)!,
      progress: Color.lerp(progress, other.progress, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      link: Color.lerp(link, other.link, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
    );
  }
}

extension BrandContext on BuildContext {
  BrandColors get brand =>
      Theme.of(this).extension<BrandColors>() ?? BrandColors.makazi;
}
