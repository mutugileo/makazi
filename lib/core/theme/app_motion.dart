import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const Duration microInteractionDuration = Duration(milliseconds: 150);
  static const Duration shortFeedbackDuration = Duration(milliseconds: 200);
  static const Duration stateTransitionDuration = Duration(milliseconds: 300);
  static const Duration primaryActionEmphasizedDuration = Duration(
    milliseconds: 400,
  );

  static const Curve standardEasing = Curves.easeInOutCubic;
  static const Curve deceleratedEasing = Curves.easeOutCubic;
  static const Curve acceleratedEasing = Curves.easeInCubic;
  static const Curve emphasizedEasing = Curves.easeInOutCubicEmphasized;
}

@immutable
class AppMotionThemeExtension extends ThemeExtension<AppMotionThemeExtension> {
  const AppMotionThemeExtension({
    required this.microInteractionDuration,
    required this.shortFeedbackDuration,
    required this.stateTransitionDuration,
    required this.primaryActionEmphasizedDuration,
    required this.standardEasing,
    required this.deceleratedEasing,
    required this.emphasizedEasing,
  });

  const AppMotionThemeExtension.regular()
    : microInteractionDuration = AppMotion.microInteractionDuration,
      shortFeedbackDuration = AppMotion.shortFeedbackDuration,
      stateTransitionDuration = AppMotion.stateTransitionDuration,
      primaryActionEmphasizedDuration =
          AppMotion.primaryActionEmphasizedDuration,
      standardEasing = AppMotion.standardEasing,
      deceleratedEasing = AppMotion.deceleratedEasing,
      emphasizedEasing = AppMotion.emphasizedEasing;

  final Duration microInteractionDuration;
  final Duration shortFeedbackDuration;
  final Duration stateTransitionDuration;
  final Duration primaryActionEmphasizedDuration;
  final Curve standardEasing;
  final Curve deceleratedEasing;
  final Curve emphasizedEasing;

  @override
  AppMotionThemeExtension copyWith({
    Duration? microInteractionDuration,
    Duration? shortFeedbackDuration,
    Duration? stateTransitionDuration,
    Duration? primaryActionEmphasizedDuration,
    Curve? standardEasing,
    Curve? deceleratedEasing,
    Curve? emphasizedEasing,
  }) {
    return AppMotionThemeExtension(
      microInteractionDuration:
          microInteractionDuration ?? this.microInteractionDuration,
      shortFeedbackDuration:
          shortFeedbackDuration ?? this.shortFeedbackDuration,
      stateTransitionDuration:
          stateTransitionDuration ?? this.stateTransitionDuration,
      primaryActionEmphasizedDuration:
          primaryActionEmphasizedDuration ??
          this.primaryActionEmphasizedDuration,
      standardEasing: standardEasing ?? this.standardEasing,
      deceleratedEasing: deceleratedEasing ?? this.deceleratedEasing,
      emphasizedEasing: emphasizedEasing ?? this.emphasizedEasing,
    );
  }

  @override
  ThemeExtension<AppMotionThemeExtension> lerp(
    covariant ThemeExtension<AppMotionThemeExtension>? other,
    double t,
  ) {
    if (other is! AppMotionThemeExtension) {
      return this;
    }
    return AppMotionThemeExtension(
      microInteractionDuration: _lerpDuration(
        microInteractionDuration,
        other.microInteractionDuration,
        t,
      ),
      shortFeedbackDuration: _lerpDuration(
        shortFeedbackDuration,
        other.shortFeedbackDuration,
        t,
      ),
      stateTransitionDuration: _lerpDuration(
        stateTransitionDuration,
        other.stateTransitionDuration,
        t,
      ),
      primaryActionEmphasizedDuration: _lerpDuration(
        primaryActionEmphasizedDuration,
        other.primaryActionEmphasizedDuration,
        t,
      ),
      standardEasing: t < 0.5 ? standardEasing : other.standardEasing,
      deceleratedEasing: t < 0.5 ? deceleratedEasing : other.deceleratedEasing,
      emphasizedEasing: t < 0.5 ? emphasizedEasing : other.emphasizedEasing,
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final micros =
        (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round();
    return Duration(microseconds: micros);
  }
}
