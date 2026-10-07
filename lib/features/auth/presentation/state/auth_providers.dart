import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_mode.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_unlock.dart';
import '../../data/device_lock_store.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_models.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Supabase Auth in the live app; the in-memory demo accounts only in tests
/// and the offline demo build.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(liveDataProvider)
      ? SupabaseAuthRepository()
      : DemoAuthRepository(),
);

/// The PIN record for this phone: Keychain / Keystore in the live app.
final deviceLockStoreProvider = Provider<DeviceLockStore>(
  (ref) => ref.watch(liveDataProvider)
      ? SecureDeviceLockStore()
      : MemoryDeviceLockStore(),
);

final biometricUnlockProvider = Provider<BiometricUnlock>(
  (ref) => ref.watch(liveDataProvider)
      ? DeviceBiometricUnlock()
      : const NoBiometricUnlock(),
);

/// What a cold start found on this phone (see restoreDeviceSession in
/// main.dart). Signed out unless a session and a PIN were both kept.
final restoredDeviceProvider = Provider<RestoredDevice>(
  (ref) => const RestoredDevice.none(),
);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
