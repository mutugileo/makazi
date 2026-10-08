import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Same family as the admin (PropAdmin/src/styles/global.css): Baloo 2 for
// everything. editorialSerif keeps its name so headings and amounts stay one
// call away from a different face if the brand changes again.
abstract final class AppTypography {
  static TextTheme createTextTheme(Color defaultTextColor) {
    final baseTextTheme = Typography.material2021().black;
    return GoogleFonts.baloo2TextTheme(
      baseTextTheme,
    ).apply(bodyColor: defaultTextColor, displayColor: defaultTextColor);
  }

  static TextStyle editorialSerif({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.baloo2(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    bool tabularFigures = false,
  }) {
    return GoogleFonts.baloo2(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: tabularFigures
          ? const [FontFeature.tabularFigures()]
          : null,
    );
  }
}
