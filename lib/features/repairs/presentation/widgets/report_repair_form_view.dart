import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/repair_ticket.dart';
import '../state/repairs_providers.dart';

class ReportRepairFormView extends ConsumerStatefulWidget {
  const ReportRepairFormView({super.key});

  @override
  ConsumerState<ReportRepairFormView> createState() =>
      _ReportRepairFormViewState();
}

class _ReportRepairFormViewState extends ConsumerState<ReportRepairFormView> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final initialDesc = ref.read(repairsProvider).description;
    _descriptionController = TextEditingController(text: initialDesc);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repairsProvider);
    final notifier = ref.read(repairsProvider.notifier);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

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
                onTap: notifier.closeNewRequest,
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
                  'Report a repair',
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
          Text(
            'CATEGORY',
            style: AppTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final cat in RepairCategory.values)
                _CategoryChip(
                  label: cat.label,
                  isSelected: state.selectedCategory == cat,
                  onTap: () => notifier.selectCategory(cat),
                  motion: motion,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'DESCRIPTION',
            style: AppTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _descriptionController,
              onChanged: notifier.updateDescription,
              maxLines: 4,
              minLines: 4,
              style: AppTypography.sans(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    'Describe what needs fixing, like a leaking tap or faulty switch',
                hintStyle: AppTypography.sans(
                  fontSize: 14,
                  color: AppColors.textSubtle,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: notifier.togglePhotoAttachment,
            child: CustomPaint(
              painter: const _DashedBorderPainter(
                color: Color(0xFFCDD5C9),
                radius: 20,
              ),
              child: Container(
                width: double.infinity,
                height: 104,
                decoration: BoxDecoration(
                  color: state.attachedPhotoCount > 0
                      ? AppColors.mintBackground.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: state.attachedPhotoCount > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.mintAccent,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '1 photo attached (tap to remove)',
                              style: AppTypography.sans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mintAccent,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Add photos',
                          style: AppTypography.sans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.canSubmit ? notifier.submitRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.pureWhite,
                disabledBackgroundColor: AppColors.forestGreen.withValues(
                  alpha: 0.4,
                ),
                disabledForegroundColor: AppColors.pureWhite.withValues(
                  alpha: 0.6,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.pureWhite,
                        ),
                      ),
                    )
                  : Text(
                      'Submit request',
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.motion,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppMotionThemeExtension motion;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: motion.microInteractionDuration,
        curve: motion.standardEasing,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forestGreen : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, this.radius = 20.0});

  final Color color;
  final double radius;
  static const double _strokeWidth = 1.2;
  static const double _dashWidth = 5.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + _dashWidth < metric.length)
            ? _dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
