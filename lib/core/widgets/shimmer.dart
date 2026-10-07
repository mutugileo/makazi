import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Sweeps a soft highlight across [child] while content loads. Every
/// [SkeletonBox] underneath shimmers together, so a whole screen moves as one.
/// Holds still when the system asks for reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = AppColors.borderLight,
    this.highlightColor = AppColors.pageBackground,
    this.period = const Duration(milliseconds: 1400),
  });

  /// Colours for shimmer on the dark hero card.
  const Shimmer.onDark({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  }) : baseColor = AppColors.forestGreenSurface,
       highlightColor = AppColors.forestGreenLight;

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // The band travels from just off the left edge to just off the right.
        final t = _controller.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
            stops: [
              (t - 0.3).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A placeholder block inside a [Shimmer]. Painted in a solid colour that the
/// shimmer's gradient replaces.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppSpacing.radiusSm,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
