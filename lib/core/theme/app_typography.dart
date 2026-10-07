import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Same pairing as the admin (PropAdmin/src/styles/global.css): Newsreader for
// editorial headings and amounts, Nunito Sans for everything else.
abstract final class AppTypography {
  static TextTheme createTextTheme(Color defaultTextColor) {
    final baseTextTheme = Typography.material2021().black;
    return GoogleFonts.nunitoSansTextTheme(
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
    return GoogleFonts.newsreader(
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
    return GoogleFonts.nunitoSans(
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
