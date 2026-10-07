import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_unlock.dart';
import '../../data/device_lock_store.dart';
import '../../domain/auth_models.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  AuthNotifier({this.initialStage, this.initialPhone, this.initialFirstName});

  /// Tests start already unlocked.
  final AuthStage? initialStage;
  final String? initialPhone;
  final String? initialFirstName;

  DeviceLock? _cachedLock;
  String? _pin;

  DeviceLockStore get _lockStore => ref.read(deviceLockStoreProvider);
  BiometricUnlock get _biometrics => ref.read(biometricUnlockProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final restored = ref.watch(restoredDeviceProvider);

    _lockStore.read().then((l) {
      if (l != null) _cachedLock = l;
    });

    if (initialStage != null) {
      return AuthState(
        stage: initialStage!,
        phone: initialPhone ?? restored.phone,
        firstName: initialFirstName ?? restored.firstName,
      );
    }

    if (restored.canUnlockWithPin) {
      return AuthState(
        stage: AuthStage.locked,
        phone: restored.phone,
        firstName: restored.firstName,
        biometricLabel: restored.biometricsEnabled
            ? restored.biometricLabel
            : null,
        failedPinAttempts: restored.failedAttempts,
      );
    }

    return AuthState(stage: AuthStage.signedOut, phone: restored.phone);
  }

  Future<void> signIn({required String phone, required String password}) async {
    if (state.isBusy) return;
    final normalized = normalizeKenyanPhone(phone);
    if (normalized == null) {
      state = state.copyWith(
        errorText: () =>
            'Enter your Safaricom or Airtel number, e.g. 0712 345 678',
      );
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorText: () => 'Enter your password');
      return;
    }

    state = state.copyWith(isBusy: true, errorText: () => null);
    final outcome = await _repository.signIn(
      phone: normalized,
      password: password,
    );
    if (!ref.mounted) return;

    state = switch (outcome) {
      SignInOutcome.invalidCredentials => state.copyWith(
        isBusy: false,
        errorText: () => 'That phone number and password don\'t match',
      ),
      SignInOutcome.oneTimePasswordExpired => state.copyWith(
        isBusy: false,
        errorText: () =>
            'That one-time password has expired. Ask your property manager for a new one.',
      ),
      SignInOutcome.networkError => state.copyWith(
        isBusy: false,
        errorText: () =>
            'Couldn\'t reach Makazi. Check your connection and try again.',
      ),
      SignInOutcome.mustChangePassword => AuthState(
        stage: AuthStage.mustChangePassword,
        phone: normalized,
        firstName: _firstNameForPhone(normalized),
      ),
      SignInOutcome.success => AuthState(
        stage: AuthStage.createPin,
        phone: normalized,
        firstName: _firstNameForPhone(normalized),
      ),
    };
  }

  Future<void> changePassword({
    required String newPassword,
    required String confirmation,
  }) async {
    if (state.isBusy || state.stage != AuthStage.mustChangePassword) return;
    final problem = passwordProblem(newPassword, phone: state.phone ?? '');
    if (problem != null) {
      state = state.copyWith(errorText: () => problem);
      return;
    }
    if (newPassword != confirmation) {
      state = state.copyWith(errorText: () => 'The passwords don\'t match');
      return;
    }

    state = state.copyWith(isBusy: true, errorText: () => null);
    try {
      await _repository.changePassword(newPassword: newPassword);
    } on OneTimePasswordExpired {
      if (!ref.mounted) return;
      _endSession(
        'That one-time password has expired. Ask your property manager for a new one.',
      );
      return;
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isBusy: false,
        errorText: () => 'Could not save password. Please try again.',
      );
      return;
    }
    if (!ref.mounted) return;
    state = AuthState(
      stage: AuthStage.createPin,
      phone: state.phone,
      firstName: state.firstName,
    );
  }

  /// Returns false (with errorText set) when the PIN is too easy to guess.
  bool checkNewPin(String pin) {
    final problem = pinProblem(pin);
    state = state.copyWith(errorText: () => problem);
    return problem == null;
  }

  void createPin({required String pin, required String confirmation}) {
    if (state.stage != AuthStage.createPin) return;
    if (!checkNewPin(pin)) return;
    if (pin != confirmation) {
      state = state.copyWith(
        errorText: () => 'The PINs didn\'t match. Try again.',
      );
      return;
    }

    _pin = pin;
    final phone = state.phone ?? '';
    final userId = _repository.currentUserId ?? 'user-$phone';
    final firstName = state.firstName ?? _firstNameForPhone(phone);

    final lock = DeviceLock.create(
      userId: userId,
      phone: phone,
      pin: pin,
      firstName: firstName,
    );
    _cachedLock = lock;
    _lockStore.write(lock);

    if (_biometrics is NoBiometricUnlock) {
      state = AuthState(
        stage: AuthStage.unlocked,
        phone: phone,
        firstName: firstName,
      );
      return;
    }

    _checkBiometricsAfterPin(phone: phone, firstName: firstName);
  }

  Future<void> _checkBiometricsAfterPin({
    required String phone,
    String? firstName,
  }) async {
    final bioLabel = await _biometrics.availableLabel();
    if (!ref.mounted) return;

    if (bioLabel != null) {
      state = state.copyWith(
        stage: AuthStage.enableBiometrics,
        firstName: firstName,
        biometricLabel: () => bioLabel,
        errorText: () => null,
      );
    } else {
      state = AuthState(
        stage: AuthStage.unlocked,
        phone: phone,
        firstName: firstName,
      );
    }
  }

  Future<void> enableBiometrics() async {
    if (state.stage != AuthStage.enableBiometrics) return;
    final label = state.biometricLabel ?? 'biometrics';
    final ok = await _biometrics.authenticate('Enable $label for quick unlock');
    if (!ref.mounted) return;
    if (ok) {
      await _updateBiometricsEnabled(true);
    }
    state = AuthState(
      stage: AuthStage.unlocked,
      phone: state.phone,
      firstName: state.firstName,
    );
  }

  Future<void> skipBiometrics() async {
    if (state.stage != AuthStage.enableBiometrics) return;
    await _updateBiometricsEnabled(false);
    if (!ref.mounted) return;
    state = AuthState(
      stage: AuthStage.unlocked,
      phone: state.phone,
      firstName: state.firstName,
    );
  }

  Future<void> _updateBiometricsEnabled(bool enabled) async {
    final lock = _cachedLock ?? await _lockStore.read();
    if (lock != null) {
      final updated = lock.copyWith(biometricsEnabled: enabled);
      _cachedLock = updated;
      await _lockStore.write(updated);
    }
  }

  void clearError() {
    if (state.errorText != null) state = state.copyWith(errorText: () => null);
  }

  Future<void> unlock(String pin) async {
    if (state.stage != AuthStage.locked) return;
    var lock = _cachedLock;
    if (lock == null) {
      lock = await _lockStore.read();
      if (lock != null) _cachedLock = lock;
    }
    final matches = lock != null ? lock.matches(pin) : (pin == _pin);

    if (matches) {
      if (lock != null && lock.failedAttempts > 0) {
        final resetLock = lock.copyWith(failedAttempts: 0);
        _cachedLock = resetLock;
        _lockStore.write(resetLock);
      }
      state = AuthState(
        stage: AuthStage.unlocked,
        phone: state.phone ?? lock?.phone,
        firstName: state.firstName ?? lock?.firstName,
      );
      return;
    }

    final failed = state.failedPinAttempts + 1;
    if (lock != null) {
      final updated = lock.copyWith(failedAttempts: failed);
      _cachedLock = updated;
      _lockStore.write(updated);
    }

    if (failed >= kMaxPinAttempts) {
      _endSession(
        'Too many wrong PINs. Sign in with your password to set a new one.',
      );
      return;
    }

    final left = kMaxPinAttempts - failed;
    state = state.copyWith(
      failedPinAttempts: failed,
      errorText: () => 'Wrong PIN. $left ${left == 1 ? 'try' : 'tries'} left.',
    );
  }

  Future<void> unlockWithBiometrics() async {
    if (state.stage != AuthStage.locked) return;
    final label = state.biometricLabel ?? 'biometrics';
    final ok = await _biometrics.authenticate('Unlock Makazi with $label');
    if (!ref.mounted) return;
    if (ok) {
      if (_cachedLock != null && _cachedLock!.failedAttempts > 0) {
        final resetLock = _cachedLock!.copyWith(failedAttempts: 0);
        _cachedLock = resetLock;
        _lockStore.write(resetLock);
      }
      state = AuthState(
        stage: AuthStage.unlocked,
        phone: state.phone ?? _cachedLock?.phone,
        firstName: state.firstName ?? _cachedLock?.firstName,
      );
    }
  }

  /// Called when the app has been in the background for a while.
  void lock() {
    if (state.stage != AuthStage.unlocked) return;
    state = AuthState(
      stage: AuthStage.locked,
      phone: state.phone,
      firstName: state.firstName,
      biometricLabel: state.biometricLabel,
    );
  }

  void forgotPin() {
    _lockStore.clear();
    _cachedLock = null;
    _pin = null;
    _endSession('Sign in with your password to set a new PIN.');
  }

  Future<void> signOut() async {
    await _lockStore.clear();
    _cachedLock = null;
    _pin = null;
    await _repository.signOut();
    if (!ref.mounted) return;
    state = AuthState(stage: AuthStage.signedOut, phone: state.phone);
  }

  void _endSession(String message) {
    _lockStore.clear();
    _cachedLock = null;
    _pin = null;
    _repository.signOut();
    state = AuthState(
      stage: AuthStage.signedOut,
      phone: state.phone,
      errorText: message,
    );
  }

  String? _firstNameForPhone(String phone) {
    return switch (phone) {
      '+254733605118' => 'David',
      '+254723555019' => 'Naliaka',
      '+254720671093' => 'Joseph',
      _ => null,
    };
  }
}
