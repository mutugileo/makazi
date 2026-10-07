import 'package:flutter/material.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HeroBalanceCard extends StatelessWidget {
  const HeroBalanceCard({
    super.key,
    required this.bill,
    required this.onPayRentPressed,
    this.onBillPressed,
    this.isActive = true,
    this.asOf,
    this.recordsKeptUntil,
    this.firstBillDate,
  });

  /// The current month's bill; null before the first bill is issued.
  final MonthlyBill? bill;
  final VoidCallback onPayRentPressed;
  final VoidCallback? onBillPressed;
  final bool isActive;

  /// Today, ISO. Used to say whether the bill is overdue.
  final String? asOf;

  /// Former tenants only: when their records (and app access) end.
  final String? recordsKeptUntil;

  /// New tenants with no bill yet: when the first one is issued.
  final String? firstBillDate;

  @override
  Widget build(BuildContext context) {
    final bill = this.bill;
    final outstanding = bill?.outstanding ?? 0;
    final amountDue = outstanding > 0 ? outstanding : 0;
    final totalDue = bill?.totalDue ?? 0;
    final paid = bill?.amountPaid ?? 0;
    final progress = totalDue <= 0 ? 1.0 : (paid / totalDue).clamp(0.0, 1.0);
    final canPay = isActive && amountDue > 0;
    // Due on the 5th, grace period to the 20th, overdue after that.
    final pastDue =
        bill != null && asOf != null && asOf!.compareTo(bill.dueDate) > 0;
    final pastGrace =
        bill != null && asOf != null && asOf!.compareTo(bill.graceDate) > 0;

    final pillLabel = !isActive
        ? 'Moved out'
        : bill == null
        ? 'New'
        : bill.status.label;
    final trailingLabel = bill == null && firstBillDate != null
        ? 'First bill ${BillingDates.formatDayMonth(firstBillDate!)}'
        : !isActive
        ? (recordsKeptUntil == null
              ? 'Records kept'
              : 'Records until ${BillingDates.formatDate(recordsKeptUntil!)}')
        : amountDue == 0
        ? (outstanding < 0
              ? '${formatKes(-outstanding)} credit'
              : 'All settled')
        : pastGrace
        ? 'Overdue since ${BillingDates.formatDayMonth(bill.graceDate)}'
        : pastDue
        ? 'Grace period to ${BillingDates.formatDayMonth(bill.graceDate)}'
        : 'Due ${BillingDates.formatDayMonth(bill!.dueDate)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ConcentricArcsPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onBillPressed,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance due',
                            style: AppTypography.sans(
                              fontSize: 14,
                              color: AppColors.onDarkMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreenSurface,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                              border: Border.all(
                                color: AppColors.forestGreenLight,
                              ),
                            ),
                            child: Text(
                              pillLabel,
                              style: AppTypography.sans(
                                fontSize: 12,
                                color: AppColors.mintPillText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        formatKes(amountDue),
                        style: AppTypography.editorialSerif(
                          fontSize: 44,
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: AppColors.limeAccent,
                          backgroundColor: AppColors.onDarkTrack,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bill == null
                                  ? 'No bill yet'
                                  : '${formatKes(paid)} paid of ${formatKes(totalDue)}',
                              style: AppTypography.sans(
                                fontSize: 13,
                                color: AppColors.onDarkMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          // Flexible so longer labels ("Records until …") wrap
                          // instead of overflowing on small phones.
                          Flexible(
                            child: Text(
                              trailingLabel,
                              textAlign: TextAlign.end,
                              style: AppTypography.sans(
                                fontSize: 13,
                                color: AppColors.onDarkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canPay ? onPayRentPressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeAccent,
                      foregroundColor: AppColors.forestGreenDark,
                      disabledBackgroundColor: AppColors.onDarkTrack,
                      disabledForegroundColor: AppColors.onDarkMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          canPay ? 'Pay rent' : 'Nothing due',
                          style: AppTypography.sans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: canPay
                                ? AppColors.forestGreenDark
                                : AppColors.onDarkMuted,
                          ),
                        ),
                        if (canPay) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.forestGreenDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcentricArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forestGreenSurface.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.9, size.height * 0.15);
    canvas.drawCircle(center, 70, paint);
    canvas.drawCircle(center, 120, paint);
    canvas.drawCircle(center, 170, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
