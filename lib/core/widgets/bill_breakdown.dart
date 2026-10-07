import 'package:flutter/material.dart';
import '../billing/billing_engine.dart';
import '../billing/billing_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One bill laid out like a row of the owner's spreadsheet: this month's
/// charges, what was carried in, what was paid and what carries forward.
class BillBreakdown extends StatelessWidget {
  const BillBreakdown({super.key, required this.bill});

  final MonthlyBill bill;

  @override
  Widget build(BuildContext context) {
    final previousMonth = BillingDates.monthLabel(
      BillingDates.addMonths(bill.month, -1),
    ).split(' ').first;

    return Column(
      children: [
        for (final line in bill.lines)
          _Row(
            label: _lineLabel(line),
            detail: line.kind == BillLineKind.water && bill.water != null
                ? '${bill.water!.units} units × ${formatKes(bill.water!.rate)}'
                : line.kind == BillLineKind.rent && bill.rentDays != null
                ? '${bill.rentDays!.days} of ${bill.rentDays!.of} days'
                : null,
            value: formatKes(line.amount),
          ),
        if (bill.balanceBf != 0)
          _Row(
            label: bill.balanceBf > 0
                ? 'Balance from $previousMonth'
                : 'Credit from $previousMonth',
            value: formatKes(bill.balanceBf),
            valueColor: bill.balanceBf > 0
                ? AppColors.statusUnpaidText
                : AppColors.statusCreditText,
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
        _Row(label: 'Total due', value: formatKes(bill.totalDue), bold: true),
        _Row(
          label: bill.datePaid == null
              ? 'Paid'
              : 'Paid · ${BillingDates.formatDayMonth(bill.datePaid!)}',
          value: formatKes(-bill.amountPaid),
        ),
        _Row(
          label: bill.outstanding < 0
              ? 'Credit carried forward'
              : 'Outstanding',
          value: formatKes(bill.outstanding.abs()),
          bold: true,
          valueColor: bill.outstanding > 0
              ? AppColors.statusUnpaidText
              : bill.outstanding < 0
              ? AppColors.statusCreditText
              : AppColors.statusPaidText,
        ),
      ],
    );
  }

  static String _lineLabel(BillLine line) => switch (line.kind) {
    BillLineKind.deposit => 'Deposit (refundable)',
    _ => line.kind.label,
  };
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.detail,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? detail;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.sans(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                    color: bold ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail!,
                      style: AppTypography.sans(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.sans(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
              tabularFigures: true,
            ),
          ),
        ],
      ),
    );
  }
}
