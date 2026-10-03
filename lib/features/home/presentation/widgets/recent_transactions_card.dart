import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key, required this.onSeeAllPressed});

  final VoidCallback onSeeAllPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: AppTypography.editorialSerif(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSeeAllPressed,
              child: Text(
                'See all',
                style: AppTypography.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mintAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Column(
            children: [
              _TransactionTile(
                initial: 'M',
                title: 'Rent, October 2026 (part)',
                subtitle: '30 Sep 2026 · M-Pesa',
                amount: 'KES 45,000',
              ),
              Divider(height: 1, color: AppColors.borderLight),
              _TransactionTile(
                initial: 'M',
                title: 'Rent, September 2026',
                subtitle: '03 Sep 2026 · M-Pesa',
                amount: 'KES 90,000',
              ),
              Divider(height: 1, color: AppColors.borderLight),
              _TransactionTile(
                initial: 'B',
                title: 'Rent, August 2026',
                subtitle: '04 Aug 2026 · Bank',
                amount: 'KES 90,000',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.initial,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String initial;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.mintBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.sans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mintAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            amount,
            style: AppTypography.sans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
