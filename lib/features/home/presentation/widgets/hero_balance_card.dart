import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HeroBalanceCard extends StatelessWidget {
  const HeroBalanceCard({
    super.key,
    required this.onPayRentPressed,
    this.isPaid = false,
  });

  final VoidCallback onPayRentPressed;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance due',
                      style: AppTypography.sans(
                        fontSize: 14,
                        color: const Color(0xFF98B9AA),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4433),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(color: const Color(0xFF1B5944)),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Partial',
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
                  isPaid ? 'KES 0' : 'KES 45,000',
                  style: AppTypography.editorialSerif(
                    fontSize: 44,
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Row(
                    children: [
                      Expanded(
                        flex: isPaid ? 1 : 1,
                        child: Container(
                          height: 4,
                          color: AppColors.limeAccent,
                        ),
                      ),
                      if (!isPaid)
                        Expanded(
                          child: Container(
                            height: 4,
                            color: const Color(0xFF154737),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isPaid
                            ? 'KES 90,000 paid of KES 90,000'
                            : 'KES 45,000 paid of KES 90,000',
                        style: AppTypography.sans(
                          fontSize: 13,
                          color: const Color(0xFF98B9AA),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isPaid ? 'All settled' : 'Due 5 Oct',
                      style: AppTypography.sans(
                        fontSize: 13,
                        color: const Color(0xFF98B9AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onPayRentPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeAccent,
                      foregroundColor: AppColors.forestGreenDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pay rent',
                          style: AppTypography.sans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreenDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.forestGreenDark,
                        ),
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
      ..color = const Color(0xFF0F4735).withValues(alpha: 0.6)
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
