import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl + AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payments',
                style: AppTypography.editorialSerif(
                  fontSize: 38,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Paid in 2026',
                      amount: 'KES 855,000',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(title: 'Balance', amount: 'KES 45,000'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'RECEIPTS',
                style: AppTypography.sans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.4,
                ),
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
                    _ReceiptTile(
                      initial: 'M',
                      title: 'Rent, October 2026 (part)',
                      receiptNumber: 'RCT-2610-0416',
                      amount: 'KES 45,000',
                    ),
                    Divider(height: 1, color: AppColors.borderLight),
                    _ReceiptTile(
                      initial: 'M',
                      title: 'Rent, September 2026',
                      receiptNumber: 'RCT-2609-0371',
                      amount: 'KES 90,000',
                    ),
                    Divider(height: 1, color: AppColors.borderLight),
                    _ReceiptTile(
                      initial: 'B',
                      title: 'Rent, August 2026',
                      receiptNumber: 'RCT-2608-0322',
                      amount: 'KES 90,000',
                    ),
                    Divider(height: 1, color: AppColors.borderLight),
                    _ReceiptTile(
                      initial: 'M',
                      title: 'Rent, July 2026',
                      receiptNumber: 'RCT-2607-0287',
                      amount: 'KES 90,000',
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.sans(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: AppTypography.editorialSerif(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({
    required this.initial,
    required this.title,
    required this.receiptNumber,
    required this.amount,
  });

  final String initial;
  final String title;
  final String receiptNumber;
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
                  receiptNumber,
                  style: AppTypography.sans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
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
