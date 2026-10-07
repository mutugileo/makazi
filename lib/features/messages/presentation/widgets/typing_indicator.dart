import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.senderName});

  final String? senderName;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion =
        Theme.of(context).extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BouncingDot(controller: _controller, delay: 0.0),
                const SizedBox(width: 4),
                _BouncingDot(controller: _controller, delay: 0.2),
                const SizedBox(width: 4),
                _BouncingDot(controller: _controller, delay: 0.4),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedOpacity(
            duration: motion.microInteractionDuration,
            opacity: 0.85,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                widget.senderName != null
                    ? '${widget.senderName} is typing…'
                    : 'Property manager is typing…',
                style: AppTypography.sans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingDot extends StatelessWidget {
  const _BouncingDot({required this.controller, required this.delay});

  final AnimationController controller;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value - delay) % 1.0;
        final curved = Curves.easeInOut.transform(
          value < 0 ? value + 1.0 : value,
        );
        final offsetY = (curved < 0.5)
            ? -4.0 * (curved * 2)
            : -4.0 * (2 - curved * 2);

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.forestGreenLight,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
