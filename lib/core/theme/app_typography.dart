import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme createTextTheme(Color defaultTextColor) {
    final baseTextTheme = Typography.material2021().black;
    return GoogleFonts.lexendTextTheme(
      baseTextTheme,
    ).apply(bodyColor: defaultTextColor, displayColor: defaultTextColor);
  }
}
