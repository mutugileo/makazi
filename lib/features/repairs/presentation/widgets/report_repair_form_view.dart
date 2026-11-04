import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prop_mgt_app/core/theme/brand_colors.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/repair_ticket.dart';
import '../state/repairs_notifier.dart';
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
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (state.attachedPhotoPath != null) {
                _showPhotoOptionsSheet(context, notifier);
              } else if (state.attachedPhotoCount > 0) {
                notifier.togglePhotoAttachment();
              } else {
                _showPhotoSourceSheet(context, notifier);
              }
            },
            child: AnimatedSwitcher(
              duration: AppMotion.shortFeedbackDuration,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: state.attachedPhotoPath != null
                  ? _PhotoPreviewCard(
                      key: ValueKey(state.attachedPhotoPath),
                      filePath: state.attachedPhotoPath!,
                      onRemove: notifier.removePhoto,
                      onChange: () => _showPhotoSourceSheet(context, notifier),
                    )
                  : CustomPaint(
                      key: ValueKey('dashed_${state.attachedPhotoCount}'),
                      painter: const _DashedBorderPainter(
                        color: AppColors.borderStrong,
                        radius: 20,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 104,
                        decoration: BoxDecoration(
                          color: state.attachedPhotoCount > 0
                              ? context.brand.tint.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: state.attachedPhotoCount > 0
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: context.brand.link,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '1 photo attached (tap to remove)',
                                      style: AppTypography.sans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: context.brand.link,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Add photos',
                                      style: AppTypography.sans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
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
                backgroundColor: context.brand.button,
                foregroundColor: context.brand.onButton,
                disabledBackgroundColor: context.brand.button.withValues(
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
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.brand.onButton,
                        ),
                      ),
                    )
                  : Text(
                      'Submit request',
                      style: AppTypography.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.brand.onButton,
                      ),
                    ),
            ),
          ),
          if (state.submitError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.submitError!,
              key: const ValueKey('repair_submit_error'),
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.statusUnpaidText,
              ),
            ),
          ],
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
          color: isSelected ? context.brand.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? context.brand.primary : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.brand.primary.withValues(alpha: 0.15),
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

Future<void> _showPhotoSourceSheet(
  BuildContext context,
  RepairsNotifier notifier,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Material(
      color: AppColors.cardBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add a photo',
                style: AppTypography.sans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Help staff understand the issue with a clear picture',
                style: AppTypography.sans(
                  fontSize: 13,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PhotoSourceOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take photo',
                subtitle: 'Use your phone camera',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  notifier.pickPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _PhotoSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                subtitle: 'Select from your photos',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  notifier.pickPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showPhotoOptionsSheet(
  BuildContext context,
  RepairsNotifier notifier,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Material(
      color: AppColors.cardBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Attached photo',
                style: AppTypography.sans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PhotoSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Change photo',
                subtitle: 'Take a new picture or choose from gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showPhotoSourceSheet(context, notifier);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _PhotoSourceOption(
                icon: Icons.delete_outline_rounded,
                title: 'Remove photo',
                subtitle: 'Delete the attached picture',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  notifier.removePhoto();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PhotoSourceOption extends StatelessWidget {
  const _PhotoSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.brand.tint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.brand.link, size: 22),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.sans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSubtle,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreviewCard extends StatelessWidget {
  const _PhotoPreviewCard({
    super.key,
    required this.filePath,
    required this.onRemove,
    required this.onChange,
  });

  final String filePath;
  final VoidCallback onRemove;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(filePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.cardBackground,
              child: Center(
                child: Text(
                  '1 photo attached',
                  style: AppTypography.sans(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Photo attached',
                        style: AppTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onChange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Change',
                      style: AppTypography.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
