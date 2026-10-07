import 'package:flutter/material.dart';
import '../billing/billing_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Paid / Partial / Unpaid / Credit, styled exactly like the admin's badges.
class BillStatusChip extends StatelessWidget {
  const BillStatusChip({super.key, required this.status});

  final BillStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (status) {
      BillStatus.paid => (
        AppColors.statusPaidBackground,
        AppColors.statusPaidText,
        AppColors.statusPaidBorder,
      ),
      BillStatus.partial => (
        AppColors.statusPartialBackground,
        AppColors.statusPartialText,
        AppColors.statusPartialBorder,
      ),
      BillStatus.unpaid => (
        AppColors.statusUnpaidBackground,
        AppColors.statusUnpaidText,
        AppColors.statusUnpaidBorder,
      ),
      BillStatus.credit => (
        AppColors.statusCreditBackground,
        AppColors.statusCreditText,
        AppColors.statusCreditBorder,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: AppTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
