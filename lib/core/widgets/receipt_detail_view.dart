import 'package:flutter/material.dart';
import '../models/payment_receipt.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ReceiptDetailView extends StatelessWidget {
  const ReceiptDetailView({
    super.key,
    required this.receipt,
    required this.onBackPressed,
  });

  final PaymentReceipt receipt;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
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
                  'Receipt',
                  style: AppTypography.editorialSerif(
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'J',
                      style: AppTypography.editorialSerif(
                        fontSize: 24,
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  receipt.companyName,
                  style: AppTypography.sans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'KRA PIN ${receipt.kraPin}',
                  style: AppTypography.sans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'AMOUNT PAID',
                  style: AppTypography.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  receipt.amount,
                  style: AppTypography.editorialSerif(
                    fontSize: 44,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(),
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(label: 'Receipt', value: receipt.receiptNumber),
                _DetailRow(label: 'Tenant', value: receipt.tenantName),
                _DetailRow(label: 'Unit', value: receipt.unit),
                _DetailRow(label: 'Date', value: receipt.date),
                _DetailRow(label: 'Method', value: receipt.method),
                _DetailRow(label: 'Reference', value: receipt.reference),
                _DetailRow(label: 'For', value: receipt.forDescription),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Downloading receipt ${receipt.receiptNumber}...',
                      style: AppTypography.sans(
                        fontSize: 14,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    backgroundColor: AppColors.forestGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintAccent,
                foregroundColor: AppColors.pureWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Download PDF',
                style: AppTypography.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.sans(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1.0;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
