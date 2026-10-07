import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint / Face ID as a quicker way to open the app than the PIN. The
/// PIN always stays as the fallback.
abstract interface class BiometricUnlock {
  /// What to call it on screen ("fingerprint", "Face ID"), or null when this
  /// phone has nothing enrolled that the app can use.
  Future<String?> availableLabel();

  /// Shows the system prompt. False if cancelled, failed or unavailable.
  Future<bool> authenticate(String reason);
}

class DeviceBiometricUnlock implements BiometricUnlock {
  DeviceBiometricUnlock([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<String?> availableLabel() async {
    if (kIsWeb) return null;
    try {
      if (!await _auth.canCheckBiometrics) return null;
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) return null;
      if (enrolled.contains(BiometricType.face)) {
        return defaultTargetPlatform == TargetPlatform.iOS
            ? 'Face ID'
            : 'face unlock';
      }
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'Touch ID'
          : 'fingerprint';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    if (kIsWeb) return false;
    try {
      // Biometrics only: the phone's own passcode is not a way into Makazi.
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Tests, web and the offline demo build.
class NoBiometricUnlock implements BiometricUnlock {
  const NoBiometricUnlock();

  @override
  Future<String?> availableLabel() async => null;

  @override
  Future<bool> authenticate(String reason) async => false;
}
