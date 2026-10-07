import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer.dart';

/// The home screen's outline while the tenant's account loads: greeting,
/// balance card, current bill and recent payments, in the same places they
/// will appear, so nothing jumps when the data arrives.
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your account',
      liveRegion: true,
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit line, "Habari, …" and the avatar.
              const Shimmer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 140, height: 12),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 210, height: 32),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonBox(height: 44, circle: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Balance card, in the hero's own green.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: const Shimmer.onDark(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 110, height: 12),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonBox(width: 190, height: 38),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonBox(width: 150, height: 12),
                      SizedBox(height: AppSpacing.lg),
                      SkeletonBox(
                        width: double.infinity,
                        height: 48,
                        radius: AppSpacing.radiusLg,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Current bill.
              const _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 120, height: 14),
                        Spacer(),
                        SkeletonBox(width: 56, height: 22, radius: 11),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    _Line(),
                    SizedBox(height: AppSpacing.sm),
                    _Line(),
                    SizedBox(height: AppSpacing.sm),
                    _Line(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Recent payments.
              const _Card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 140, height: 14),
                        Spacer(),
                        SkeletonBox(width: 48, height: 12),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    _PaymentRow(),
                    SizedBox(height: AppSpacing.md),
                    _PaymentRow(),
                    SizedBox(height: AppSpacing.md),
                    _PaymentRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Shimmer(child: child),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 90, height: 12),
        Spacer(),
        SkeletonBox(width: 64, height: 12),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(height: 36, circle: true),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120, height: 12),
              SizedBox(height: 6),
              SkeletonBox(width: 80, height: 10),
            ],
          ),
        ),
        SkeletonBox(width: 70, height: 14),
      ],
    );
  }
}
