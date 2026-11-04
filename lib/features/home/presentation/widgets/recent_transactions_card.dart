import 'package:prop_mgt_app/core/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onSeeAllPressed,
    this.onTransactionTapped,
    this.theme,
  });

  final List<PaymentReceipt> transactions;
  final VoidCallback onSeeAllPressed;
  final ValueChanged<int>? onTransactionTapped;
  final CompanyTheme? theme;

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
                    color: context.brand.link,
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
              if (displayItems.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No payments yet',
                  message: 'Your receipts appear here after you pay.',
                ),
              for (int i = 0; i < displayItems.length; i++) ...[
                _TransactionTile(
                  initial: displayItems[i].initial,
                  title: displayItems[i].forDescription,
                  subtitle:
                      '${displayItems[i].dateLabel} · ${displayItems[i].methodLabel}',
                  amount: displayItems[i].amountLabel,
                  onTap: () => onTransactionTapped?.call(i),
                  theme: theme,
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
    this.theme,
  });

  final String initial;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;
  final CompanyTheme? theme;

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
              decoration: BoxDecoration(
                color: theme != null
                    ? theme!.primaryColor.withValues(alpha: 0.12)
                    : context.brand.tint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.brand.link,
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
