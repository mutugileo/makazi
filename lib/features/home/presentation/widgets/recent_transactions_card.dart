import 'package:flutter/material.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onSeeAllPressed,
    this.onTransactionTapped,
  });

  final List<PaymentReceipt> transactions;
  final VoidCallback onSeeAllPressed;
  final ValueChanged<int>? onTransactionTapped;

  @override
  Widget build(BuildContext context) {
    final displayItems = transactions.take(3).toList();

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
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'See all',
                  style: AppTypography.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintAccent,
                  ),
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
          child: Column(
            children: [
              for (int i = 0; i < displayItems.length; i++) ...[
                _TransactionTile(
                  initial: displayItems[i].initial,
                  title: displayItems[i].forDescription,
                  subtitle:
                      '${displayItems[i].date} · ${displayItems[i].method}',
                  amount: displayItems[i].amount,
                  onTap: () => onTransactionTapped?.call(i),
                ),
                if (i < displayItems.length - 1)
                  const Divider(height: 1, color: AppColors.borderLight),
              ],
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
    required this.onTap,
  });

  final String initial;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
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
                      fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w400,
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
      ),
    );
  }
}
