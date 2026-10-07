import 'package:flutter/material.dart';

// Brand palette shared with the admin. Source of truth:
// PropAdmin/src/styles/global.css (@theme). test/unit/design_tokens_test.dart
// fails if these drift from it.
abstract final class AppColors {
  // Forest greens (--color-forest-900 … 600)
  static const Color forestGreenDark = Color(0xFF0A261F);
  static const Color forestGreen = Color(0xFF0D382B);
  static const Color forestGreenSurface = Color(0xFF134637);
  static const Color forestGreenLight = Color(0xFF1C5A47);

  // Lime (--color-lime-accent, --color-lime-hover)
  static const Color limeAccent = Color(0xFFC6EE58);
  static const Color limeAccentHover = Color(0xFFB7E344);
  static const Color limeSoft = Color(0xFFE4F98E);

  // Surfaces (--color-sand-*)
  static const Color pageBackground = Color(0xFFF3F4F0);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE7EAE4);
  static const Color borderStrong = Color(0xFFDCE0D7);

  // App accent for links and primary buttons on light screens.
  static const Color mintBackground = Color(0xFFE6F5ED);
  static const Color mintAccent = Color(0xFF0A6B48);

  // Alerts (--color-terracotta, --color-terracotta-light)
  static const Color terracotta = Color(0xFFC04A26);
  static const Color terracottaLight = Color(0xFFFFF1EC);
  static const Color actionNeededOrange = terracotta;

  // On the dark forest balance card (--color-on-dark-*)
  static const Color onDarkMuted = Color(0xFF93BDB0);
  static const Color onDarkTrack = Color(0xFF18493B);
  static const Color mintPillText = limeAccent;

  // Bill and repair statuses (--color-status-*), identical to admin badges.
  static const Color statusPaidBackground = Color(0xFFF1F8E9);
  static const Color statusPaidText = Color(0xFF2E7D32);
  static const Color statusPaidBorder = Color(0xFFC8E6C9);
  static const Color statusPartialBackground = Color(0xFFFFF8E1);
  static const Color statusPartialText = Color(0xFFB78103);
  static const Color statusPartialBorder = Color(0xFFFFE082);
  static const Color statusUnpaidBackground = Color(0xFFFDEEE9);
  static const Color statusUnpaidText = Color(0xFFC04A26);
  static const Color statusUnpaidBorder = Color(0xFFF6C6B8);
  static const Color statusCreditBackground = Color(0xFFEFF6FF);
  static const Color statusCreditText = Color(0xFF1E40AF);
  static const Color statusCreditBorder = Color(0xFFBFDBFE);
  static const Color statusResolvedBackground = statusPaidBackground;
  static const Color statusResolvedText = statusPaidText;

  // Text (--color-ink-*)
  static const Color textPrimary = Color(0xFF17231E);
  static const Color textSecondary = Color(0xFF5A6862);
  static const Color textMuted = Color(0xFF73827C);
  static const Color textSubtle = Color(0xFFA8B3AE);

  static const Color avatarBackground = forestGreen;
  static const Color avatarText = limeAccent;

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
}
