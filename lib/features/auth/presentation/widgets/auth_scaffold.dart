import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

const String kAuthBackgroundAsset = 'assets/images/login-bg.webp';

/// Shared frame for the sign-in screens. Same look as the admin login: the
/// apartment photo with a forest tint, the brand on top, and the form on a
/// floating frosted card.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Forest green shows while the photo decodes (and if it ever fails).
      backgroundColor: AppColors.forestGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            kAuthBackgroundAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          // Same tint as the admin login, so white text stays readable.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.forestGreenDark.withValues(alpha: 0.55),
                  AppColors.forestGreenDark.withValues(alpha: 0.25),
                  AppColors.forestGreenDark.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0.0,
                        constraints.maxHeight - AppSpacing.lg * 2,
                      ),
                    ),
                    // Brand at the top, card in the middle, credit at the
                    // bottom, like the admin login.
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BrandMark(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: _FrostedCard(
                            title: title,
                            subtitle: subtitle,
                            child: child,
                          ),
                        ),
                        Center(
                          child: Text(
                            'Built and maintained by Codzure Solutions Ltd',
                            style: AppTypography.sans(
                              fontSize: 11,
                              color: AppColors.pureWhite.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.limeAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'M',
            style: AppTypography.sans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreenDark,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Makazi',
              style: AppTypography.editorialSerif(
                fontSize: 20,
                color: AppColors.pureWhite,
              ),
            ),
            // Platform brand: the landlord isn't known until sign-in.
            Text(
              'Rent, bills and repairs',
              style: AppTypography.sans(
                fontSize: 12,
                color: AppColors.pureWhite.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusXl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.72),
              borderRadius: radius,
              border: Border.all(
                color: AppColors.pureWhite.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.editorialSerif(
                    fontSize: 32,
                    color: AppColors.forestGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.sans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error line used under auth forms.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        text!,
        style: AppTypography.sans(
          fontSize: 13,
          color: AppColors.statusUnpaidText,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Primary full-width button with a busy state.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.pureWhite,
          disabledBackgroundColor: AppColors.forestGreen.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.pureWhite,
                ),
              )
            : Text(
                label,
                style: AppTypography.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
      ),
    );
  }
}

InputDecoration authInputDecoration({
  required String label,
  String? hint,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.cardBackground,
    labelStyle: AppTypography.sans(fontSize: 14, color: AppColors.textMuted),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: border(AppColors.borderLight),
    enabledBorder: border(AppColors.borderLight),
    focusedBorder: border(AppColors.mintAccent, 1.5),
  );
}
