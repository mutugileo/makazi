import 'package:flutter/material.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
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
    this.theme,
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

  /// Optional company theme for landlord-specific branding.
  final CompanyTheme? theme;

  @override
  Widget build(BuildContext context) {
    final bill = this.bill;
    final outstanding = bill?.outstanding ?? 0;
    final amountDue = outstanding > 0 ? outstanding : 0;
    final totalDue = bill?.totalDue ?? 0;
    final paid = bill?.amountPaid ?? 0;
    final progress = totalDue <= 0 ? 1.0 : (paid / totalDue).clamp(0.0, 1.0);
    // A current tenant can pay at any time; paying ahead becomes credit.
    final canPay = isActive;
    // Due on dueDay, grace period to graceDay, overdue after that.
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

    final effectivePrimary = theme?.primaryColor ?? const Color(0xFF0D382B);
    final effectiveAccent = theme?.accentColor ?? const Color(0xFFC6EE58);
    final effectiveButton = theme?.buttonColor ?? effectiveAccent;
    final effectiveOnPrimary =
        theme?.onPrimaryColor ??
        (effectivePrimary.computeLuminance() > 0.35
            ? const Color(0xFF071A2C)
            : const Color(0xFFFFFFFF));
    final effectiveOnButton =
        theme?.onButtonColor ??
        (effectiveButton.computeLuminance() > 0.35
            ? const Color(0xFF071A2C)
            : const Color(0xFFFFFFFF));

    return Container(
      decoration: BoxDecoration(
        color: effectivePrimary,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ConcentricArcsPainter(
                color: effectiveOnPrimary.withValues(alpha: 0.08),
              ),
            ),
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
                              color: effectiveOnPrimary.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: effectiveOnPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                              border: Border.all(
                                color: effectiveOnPrimary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              pillLabel,
                              style: AppTypography.sans(
                                fontSize: 12,
                                color: effectiveOnPrimary,
                                fontWeight: FontWeight.w600,
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
                          color: effectiveOnPrimary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // What came in from earlier bills: arrears owed, or
                      // credit already taken off this bill.
                      if (bill != null && bill.balanceBf != 0)
                        Text(
                          bill.balanceBf > 0
                              ? 'Includes ${formatKes(bill.balanceBf)} arrears'
                              : 'After ${formatKes(-bill.balanceBf)} credit',
                          key: const ValueKey('hero_carried_balance'),
                          style: AppTypography.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: effectiveOnPrimary.withValues(alpha: 0.85),
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
                          color: theme?.progressColor ?? effectiveAccent,
                          backgroundColor: effectiveOnPrimary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Wraps rather than cutting off large amounts
                          // ("KES 182,500 paid of KES 182,500").
                          Expanded(
                            flex: 3,
                            child: Text(
                              bill == null
                                  ? 'No bill yet'
                                  : '${formatKes(paid)} paid of ${formatKes(totalDue)}',
                              style: AppTypography.sans(
                                fontSize: 13,
                                color: effectiveOnPrimary.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          // Flexible so longer labels ("Records until …") wrap
                          // instead of overflowing on small phones.
                          Flexible(
                            flex: 2,
                            child: Text(
                              trailingLabel,
                              textAlign: TextAlign.end,
                              style: AppTypography.sans(
                                fontSize: 13,
                                color: effectiveOnPrimary.withValues(
                                  alpha: 0.75,
                                ),
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
                      backgroundColor: effectiveButton,
                      foregroundColor: effectiveOnButton,
                      disabledBackgroundColor: effectiveOnPrimary.withValues(
                        alpha: 0.12,
                      ),
                      disabledForegroundColor: effectiveOnPrimary.withValues(
                        alpha: 0.4,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          canPay ? 'Pay rent' : 'Tenancy ended',
                          style: AppTypography.sans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: canPay
                                ? effectiveOnButton
                                : effectiveOnPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                        if (canPay) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: effectiveOnButton,
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
  const _ConcentricArcsPainter({this.color});

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? const Color(0xFFC6EE58).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.9, size.height * 0.15);
    canvas.drawCircle(center, 70, paint);
    canvas.drawCircle(center, 120, paint);
    canvas.drawCircle(center, 170, paint);
  }

  @override
  bool shouldRepaint(covariant _ConcentricArcsPainter oldDelegate) =>
      oldDelegate.color != color;
}
