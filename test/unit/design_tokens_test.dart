import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/theme/app_colors.dart';

// The admin's @theme in PropAdmin/src/styles/global.css is the palette's
// source of truth. This fails as soon as the app's colours drift from it.

const _pairs = <String, Color>{
  'forest-900': AppColors.forestGreenDark,
  'forest-800': AppColors.forestGreen,
  'forest-700': AppColors.forestGreenSurface,
  'forest-600': AppColors.forestGreenLight,
  'lime-accent': AppColors.limeAccent,
  'lime-hover': AppColors.limeAccentHover,
  'terracotta': AppColors.terracotta,
  'terracotta-light': AppColors.terracottaLight,
  'sand-100': AppColors.pageBackground,
  'sand-200': AppColors.borderLight,
  'sand-300': AppColors.borderStrong,
  'ink': AppColors.textPrimary,
  'ink-secondary': AppColors.textSecondary,
  'ink-muted': AppColors.textMuted,
  'ink-subtle': AppColors.textSubtle,
  'on-dark-muted': AppColors.onDarkMuted,
  'on-dark-track': AppColors.onDarkTrack,
  'status-paid-bg': AppColors.statusPaidBackground,
  'status-paid': AppColors.statusPaidText,
  'status-paid-border': AppColors.statusPaidBorder,
  'status-partial-bg': AppColors.statusPartialBackground,
  'status-partial': AppColors.statusPartialText,
  'status-partial-border': AppColors.statusPartialBorder,
  'status-unpaid-bg': AppColors.statusUnpaidBackground,
  'status-unpaid': AppColors.statusUnpaidText,
  'status-unpaid-border': AppColors.statusUnpaidBorder,
  'status-credit-bg': AppColors.statusCreditBackground,
  'status-credit': AppColors.statusCreditText,
  'status-credit-border': AppColors.statusCreditBorder,
};

void main() {
  final file = File('PropAdmin/src/styles/global.css').existsSync()
      ? File('PropAdmin/src/styles/global.css')
      : File('../PropAdmin/src/styles/global.css');
  final css = file.readAsStringSync();
  final tokens = {
    for (final m in RegExp(
      r'--color-([a-z0-9-]+):\s*#([0-9A-Fa-f]{6})\s*;',
    ).allMatches(css))
      m.group(1)!: int.parse('FF${m.group(2)}', radix: 16),
  };

  for (final entry in _pairs.entries) {
    test('AppColors matches --color-${entry.key}', () {
      expect(
        tokens.containsKey(entry.key),
        isTrue,
        reason: '--color-${entry.key} missing from global.css',
      );
      expect(
        entry.value.toARGB32().toRadixString(16).toUpperCase(),
        tokens[entry.key]!.toRadixString(16).toUpperCase(),
      );
    });
  }
}
