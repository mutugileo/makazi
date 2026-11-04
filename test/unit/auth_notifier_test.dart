import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/auth/data/auth_repository.dart';
import 'package:prop_mgt_app/features/auth/data/biometric_unlock.dart';
import 'package:prop_mgt_app/features/auth/data/demo_credentials.dart';
import 'package:prop_mgt_app/features/auth/data/device_lock_store.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        DemoAuthRepository(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

final _demo = kDemoAccounts.first;

Future<void> _signInAndCreatePin(
  ProviderContainer c, {
  String pin = '2580',
}) async {
  final auth = c.read(authProvider.notifier);
  await auth.signIn(phone: _demo.phone, password: _demo.password);
  await auth.createPin(pin: pin, confirmation: pin);
}

void main() {
  group('manager PIN', () {
    test(
      'a temporary PIN must be replaced, and the new PIN signs in later',
      () async {
        final repo = _ManagerPinRepository(managerPin: '4826');
        final c = _managerPinContainer(repo);
        final auth = c.read(authProvider.notifier);

        await auth.signIn(phone: '0733605118', password: '4826');
        expect(c.read(authProvider).stage, AuthStage.createPin);

        await auth.createPin(pin: '2580', confirmation: '2580');
        expect(c.read(authProvider).stage, isNot(AuthStage.createPin));
        expect(repo.isCurrentUserTemporary, isFalse);

        // Lost session or a new phone: the PIN alone gets back in.
        await auth.signOut();
        await auth.signIn(phone: '0733605118', password: '4826');
        expect(c.read(authProvider).errorText, contains("don't match"));
        await auth.signIn(phone: '0733605118', password: '2580');
        expect(c.read(authProvider).stage, AuthStage.unlocked);
      },
    );

    test('a PIN that fails to save stays on Create a PIN', () async {
      final repo = _ManagerPinRepository(managerPin: '4826')..failSave = true;
      final c = _managerPinContainer(repo);
      final auth = c.read(authProvider.notifier);

      await auth.signIn(phone: '0733605118', password: '4826');
      await auth.createPin(pin: '2580', confirmation: '2580');

      final state = c.read(authProvider);
      expect(state.stage, AuthStage.createPin);
      expect(state.isBusy, isFalse);
      expect(state.errorText, contains("Couldn't save your PIN"));
    });
  });

  group('normalizeKenyanPhone', () {
    test('accepts local and international formats', () {
      expect(normalizeKenyanPhone('0733 605 118'), '+254733605118');
      expect(normalizeKenyanPhone('+254 733 605 118'), '+254733605118');
      expect(normalizeKenyanPhone('254733605118'), '+254733605118');
      expect(normalizeKenyanPhone('0110 123 456'), '+254110123456');
    });

    test('rejects numbers that are not Kenyan mobiles', () {
      expect(normalizeKenyanPhone('0201234567'), isNull);
      expect(normalizeKenyanPhone('12345'), isNull);
      expect(normalizeKenyanPhone(''), isNull);
    });
  });

  group('pinProblem', () {
    test('rejects easy PINs', () {
      expect(pinProblem('1111'), isNotNull);
      expect(pinProblem('1234'), isNotNull);
      expect(pinProblem('9876'), isNotNull);
      expect(pinProblem('12a4'), isNotNull);
      expect(pinProblem('2580'), isNull);
    });
  });

  group('AuthNotifier', () {
    test('starts signed out', () {
      expect(_container().read(authProvider).stage, AuthStage.signedOut);
    });

    test('wrong password and unknown number get the same message', () async {
      final c = _container();
      final auth = c.read(authProvider.notifier);

      await auth.signIn(phone: _demo.phone, password: 'wrong');
      final wrongPassword = c.read(authProvider).errorText;
      await auth.signIn(phone: '0799 000 000', password: _demo.password);

      expect(c.read(authProvider).stage, AuthStage.signedOut);
      expect(c.read(authProvider).errorText, wrongPassword);
    });

    test('a temporary password goes straight to Create a PIN', () async {
      final c = _container();
      await c
          .read(authProvider.notifier)
          .signIn(phone: _demo.phone, password: _demo.password);

      expect(c.read(authProvider).stage, AuthStage.createPin);
      expect(c.read(authProvider).phone, '+254733605118');
    });

    test('temporary password, then PIN, then unlocked', () async {
      final c = _container();
      await _signInAndCreatePin(c);
      expect(c.read(authProvider).stage, AuthStage.unlocked);
    });

    test(
      'the chosen PIN becomes the password; older ones stop working',
      () async {
        final c = _container();
        await _signInAndCreatePin(c);
        final auth = c.read(authProvider.notifier);
        await auth.signOut();

        await auth.signIn(phone: _demo.phone, password: _demo.password);
        expect(c.read(authProvider).stage, AuthStage.signedOut);

        // Signing in again (new phone, lost session) needs only the PIN.
        await auth.signIn(phone: _demo.phone, password: '2580');
        expect(c.read(authProvider).stage, AuthStage.unlocked);
      },
    );

    test('mismatched PIN confirmation is rejected', () async {
      final c = _container();
      final auth = c.read(authProvider.notifier);
      await auth.signIn(phone: _demo.phone, password: _demo.password);

      await auth.createPin(pin: '2580', confirmation: '2581');
      expect(c.read(authProvider).stage, AuthStage.createPin);
      expect(c.read(authProvider).errorText, contains("didn't match"));
    });

    test('lock and unlock with the PIN', () async {
      final c = _container();
      await _signInAndCreatePin(c);
      final auth = c.read(authProvider.notifier)..lock();
      expect(c.read(authProvider).stage, AuthStage.locked);

      auth.unlock('2580');
      expect(c.read(authProvider).stage, AuthStage.unlocked);
    });

    test('five wrong PINs end the session', () async {
      final c = _container();
      await _signInAndCreatePin(c);
      final auth = c.read(authProvider.notifier)..lock();

      for (var i = 0; i < kMaxPinAttempts - 1; i++) {
        auth.unlock('0000');
      }
      expect(c.read(authProvider).stage, AuthStage.locked);
      expect(c.read(authProvider).errorText, contains('1 try left'));

      auth.unlock('0000');
      expect(c.read(authProvider).stage, AuthStage.signedOut);
      expect(c.read(authProvider).errorText, contains('Too many wrong PINs'));
    });

    test('forgot PIN goes back to password sign-in', () async {
      final c = _container();
      await _signInAndCreatePin(c);
      c.read(authProvider.notifier)
        ..lock()
        ..forgotPin();

      expect(c.read(authProvider).stage, AuthStage.signedOut);
      expect(c.read(authProvider).phone, '+254733605118');
    });

    test('cold start with stored device lock starts in locked stage', () async {
      final lock = DeviceLock.create(
        userId: 'user-1',
        phone: '+254733605118',
        pin: '2580',
        firstName: 'David',
      );
      final restored = RestoredDevice(
        hasSession: true,
        phone: lock.phone,
        firstName: lock.firstName,
        biometricsEnabled: true,
        biometricLabel: 'fingerprint',
      );

      final c = ProviderContainer(
        overrides: [
          restoredDeviceProvider.overrideWithValue(restored),
          deviceLockStoreProvider.overrideWithValue(
            MemoryDeviceLockStore(lock),
          ),
        ],
      );
      addTearDown(c.dispose);

      final state = c.read(authProvider);
      expect(state.stage, AuthStage.locked);
      expect(state.phone, '+254733605118');
      expect(state.firstName, 'David');
      expect(state.biometricLabel, 'fingerprint');

      // Unlocking with PIN succeeds
      await c.read(authProvider.notifier).unlock('2580');
      expect(c.read(authProvider).stage, AuthStage.unlocked);
    });

    test('unlock with biometrics opens the app', () async {
      final lock = DeviceLock.create(
        userId: 'user-1',
        phone: '+254733605118',
        pin: '2580',
        firstName: 'David',
      );
      final bio = _TestBiometrics(shouldAuthenticate: true);
      final c = ProviderContainer(
        overrides: [
          restoredDeviceProvider.overrideWithValue(
            RestoredDevice(
              hasSession: true,
              phone: lock.phone,
              firstName: lock.firstName,
              biometricsEnabled: true,
              biometricLabel: 'fingerprint',
            ),
          ),
          deviceLockStoreProvider.overrideWithValue(
            MemoryDeviceLockStore(lock),
          ),
          biometricUnlockProvider.overrideWithValue(bio),
        ],
      );
      addTearDown(c.dispose);

      expect(c.read(authProvider).stage, AuthStage.locked);
      await c.read(authProvider.notifier).unlockWithBiometrics();
      expect(c.read(authProvider).stage, AuthStage.unlocked);
    });
  });
}

class _TestBiometrics implements BiometricUnlock {
  const _TestBiometrics({this.shouldAuthenticate = true});

  final bool shouldAuthenticate;

  @override
  Future<String?> availableLabel() async => 'fingerprint';

  @override
  Future<bool> authenticate(String reason) async => shouldAuthenticate;
}

/// Behaves like Supabase for one tenant: a manager-issued PIN is temporary
/// until the tenant saves their own, which replaces it as the password.
class _ManagerPinRepository implements AuthRepository {
  _ManagerPinRepository({required String managerPin}) : _password = managerPin;

  String _password;
  bool _temporary = true;
  bool _signedIn = false;
  bool failSave = false;

  @override
  Future<SignInOutcome> signIn({
    required String phone,
    required String password,
  }) async {
    if (password != _password) return SignInOutcome.invalidCredentials;
    _signedIn = true;
    return SignInOutcome.success;
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    if (failSave) throw Exception('offline');
    _password = newPassword;
    _temporary = false;
  }

  @override
  Future<void> signOut() async => _signedIn = false;

  @override
  String? get currentUserId => _signedIn ? 'tenant-1' : null;

  @override
  bool get isCurrentUserTemporary => _signedIn && _temporary;

  @override
  Stream<void> get sessionEnded => const Stream.empty();
}

ProviderContainer _managerPinContainer(_ManagerPinRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}
