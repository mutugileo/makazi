import 'package:flutter/foundation.dart';
import '../../domain/auth_models.dart';

@immutable
class AuthState {
  const AuthState({
    required this.stage,
    this.phone,
    this.isBusy = false,
    this.errorText,
    this.failedPinAttempts = 0,
    this.firstName,
    this.biometricLabel,
  });

  final AuthStage stage;

  /// Normalised (+254…) once signed in; kept after sign-out to prefill.
  final String? phone;
  final bool isBusy;
  final String? errorText;
  final int failedPinAttempts;

  /// Remembered on this phone, for the unlock greeting.
  final String? firstName;

  /// "fingerprint", "Face ID"…: set while offering it after the PIN is
  /// chosen, and on the lock screen when the tenant turned it on.
  final String? biometricLabel;

  int get pinAttemptsLeft => kMaxPinAttempts - failedPinAttempts;

  AuthState copyWith({
    AuthStage? stage,
    String? phone,
    bool? isBusy,
    String? Function()? errorText,
    int? failedPinAttempts,
    String? firstName,
    String? Function()? biometricLabel,
  }) {
    return AuthState(
      stage: stage ?? this.stage,
      phone: phone ?? this.phone,
      isBusy: isBusy ?? this.isBusy,
      errorText: errorText != null ? errorText() : this.errorText,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      firstName: firstName ?? this.firstName,
      biometricLabel: biometricLabel != null
          ? biometricLabel()
          : this.biometricLabel,
    );
  }
}
