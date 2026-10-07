import '../../../../core/config/supabase_config.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';
import 'biometric_unlock.dart';
import 'device_lock_store.dart';
import 'supabase_auth_repository.dart';

/// Reads the persistent Keychain / Keystore device lock record on app launch
/// and determines whether the app can open directly in the locked state
/// with PIN or biometric authentication, instead of asking for a password.
Future<RestoredDevice> restoreDeviceSession({
  DeviceLockStore? lockStore,
  AuthRepository? authRepository,
  BiometricUnlock? biometricUnlock,
}) async {
  try {
    final store =
        lockStore ??
        (SupabaseConfig.isConfigured
            ? SecureDeviceLockStore()
            : MemoryDeviceLockStore());
    final lock = await store.read();
    if (lock == null) return const RestoredDevice.none();

    if (lock.failedAttempts >= kMaxPinAttempts) {
      await store.clear();
      return const RestoredDevice.none();
    }

    final auth =
        authRepository ??
        (SupabaseConfig.isConfigured
            ? SupabaseAuthRepository()
            : DemoAuthRepository());

    final hasSession = SupabaseConfig.isConfigured
        ? (auth.currentUserId != null)
        : true;

    if (!hasSession) {
      return const RestoredDevice.none();
    }

    final bio =
        biometricUnlock ??
        (SupabaseConfig.isConfigured
            ? DeviceBiometricUnlock()
            : const NoBiometricUnlock());
    final bioLabel = await bio.availableLabel();

    return RestoredDevice(
      hasSession: true,
      phone: lock.phone,
      firstName: lock.firstName,
      biometricsEnabled: lock.biometricsEnabled,
      biometricLabel: bioLabel,
      failedAttempts: lock.failedAttempts,
    );
  } catch (_) {
    return const RestoredDevice.none();
  }
}
