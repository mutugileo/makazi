import 'package:flutter/material.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bill_breakdown.dart';
import '../../../../core/widgets/bill_status_chip.dart';

/// One month's bill in full: charges, meter readings and the payments that
/// went towards it.
class BillDetailView extends StatelessWidget {
  const BillDetailView({
    super.key,
    required this.bill,
    required this.receipts,
    required this.onBackPressed,
    required this.onReceiptSelected,
  });

  final MonthlyBill bill;
  final List<PaymentReceipt> receipts;
  final VoidCallback onBackPressed;
  final ValueChanged<PaymentReceipt> onReceiptSelected;

  @override
  Widget build(BuildContext context) {
    final kindNote = switch (bill.kind) {
      BillKind.moveIn =>
        'Your first bill: deposit, plus rent for the days left in the month. '
            'Water is billed from next month.',
      BillKind.finalBill =>
        'Final bill after moving out: last water reading, deposit applied.',
      BillKind.monthly => null,
    };
    final water = bill.water;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  BillingDates.monthLabel(bill.month),
                  style: AppTypography.editorialSerif(
                    fontSize: 34,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due ${BillingDates.formatDate(bill.dueDate)} · '
                        'grace to ${BillingDates.formatDayMonth(bill.graceDate)}',
                        style: AppTypography.sans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    BillStatusChip(status: bill.status),
                  ],
                ),
                if (kindNote != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    kindNote,
                    style: AppTypography.sans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                BillBreakdown(bill: bill),
              ],
            ),
          ),
          if (water != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 20,
                    color: AppColors.mintAccent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Meter ${groupThousands(water.previousReading)} → '
                      '${groupThousands(water.currentReading)} · '
                      '${water.units} units used in '
                      '${BillingDates.monthLabel(BillingDates.addMonths(bill.month, -1)).split(' ').first}',
                      style: AppTypography.sans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        tabularFigures: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'PAYMENTS',
            style: AppTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (receipts.isEmpty)
            Text(
              'No payments towards this bill yet.',
              style: AppTypography.sans(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            )
          else
            Material(
              color: AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < receipts.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.borderLight),
                    ListTile(
                      onTap: () => onReceiptSelected(receipts[i]),
                      title: Text(
                        '${receipts[i].dateLabel} · ${receipts[i].method}',
                        style: AppTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        receipts[i].receiptNumber,
                        style: AppTypography.sans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: Text(
                        receipts[i].amountLabel,
                        style: AppTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          tabularFigures: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
