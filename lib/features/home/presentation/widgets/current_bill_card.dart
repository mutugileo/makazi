import 'package:flutter/material.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bill_breakdown.dart';
import '../../../../core/widgets/bill_status_chip.dart';

/// "October bill": rent, water, garbage and anything carried forward.
class CurrentBillCard extends StatelessWidget {
  const CurrentBillCard({super.key, required this.bill, this.onTap});

  final MonthlyBill bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final monthName = BillingDates.monthLabel(bill.month).split(' ').first;
    final title = switch (bill.kind) {
      BillKind.moveIn => 'Move-in bill',
      BillKind.finalBill => 'Final bill',
      BillKind.monthly => '$monthName bill',
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.editorialSerif(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                BillStatusChip(status: bill.status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Issued ${BillingDates.formatDayMonth('${bill.month}-01')} · '
              'due ${BillingDates.formatDayMonth(bill.dueDate)} · '
              'grace to ${BillingDates.formatDayMonth(bill.graceDate)}',
              style: AppTypography.sans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            BillBreakdown(bill: bill),
          ],
        ),
      ),
    );
  }
}
