import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/features/auth/data/auth_repository.dart';
import 'package:prop_mgt_app/features/auth/data/demo_credentials.dart';
import 'package:prop_mgt_app/features/auth/data/device_lock_store.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';

/// Stands in for the Phase 2 Supabase repository.
class _RealRepository implements AuthRepository {
  @override
  Future<SignInOutcome> signIn({
    required String phone,
    required String password,
  }) async => SignInOutcome.invalidCredentials;

  @override
  Future<void> changePassword({required String newPassword}) async {}

  @override
  Future<void> signOut() async {}

  @override
  String? get currentUserId => null;

  @override
  Stream<void> get sessionEnded => const Stream.empty();
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('pin_key_$digit')));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first sign-in: temporary password, new password, PIN, home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            DemoAuthRepository(latency: Duration.zero),
          ),
        ],
        child: const PropMgtApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    final demo = kDemoAccounts.first;

    // The demo hint fills both fields.
    expect(find.textContaining('DEMO ACCOUNT'), findsNWidgets(3));
    await tester.tap(find.text('Fill in').first);
    await tester.pump();
    expect(find.text(demo.phone), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('sign_in_phone')),
      demo.phone,
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_in_password')),
      'not-it',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text("That phone number and password don't match"),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('sign_in_password')),
      demo.password,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a password'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('new_password')),
      'mvua ya asubuhi',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm_password')),
      'mvua ya asubuhi',
    );
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(find.text('Create a PIN'), findsOneWidget);
    await _enterPin(tester, '1234');
    expect(find.text('Avoid number sequences like 1234'), findsOneWidget);
    await _enterPin(tester, '2580');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await _enterPin(tester, '2580');

    expect(find.text('Habari, David'), findsOneWidget);

    // Sign out from the account sheet; the phone number is remembered.
    await tester.tap(find.byKey(const ValueKey('account_avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('0733605118'), findsOneWidget);
  });

  testWidgets('the demo hint never shows with a real sign-in backend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_RealRepository()),
        ],
        child: const PropMgtApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.textContaining('DEMO ACCOUNT'), findsNothing);
  });

  testWidgets(
    'subsequent login: opens locked screen and PIN unlocks directly without password',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lock = DeviceLock.create(
        userId: 'demo-user',
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              DemoAuthRepository(latency: Duration.zero),
            ),
            restoredDeviceProvider.overrideWithValue(restored),
            deviceLockStoreProvider.overrideWithValue(
              MemoryDeviceLockStore(lock),
            ),
          ],
          child: const PropMgtApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify it opened directly in the locked state, NOT sign-in screen
      expect(find.text('Karibu tena, David'), findsOneWidget);
      expect(find.text('Enter your PIN to open Makazi.'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      expect(find.byKey(const ValueKey('sign_in_password')), findsNothing);

      // Verify biometric button is visible
      expect(
        find.byKey(const ValueKey('biometric_unlock_button')),
        findsOneWidget,
      );

      // Unlock with PIN
      await _enterPin(tester, '2580');

      // Home is reached directly without ever asking for a password!
      expect(find.text('Habari, David'), findsOneWidget);
    },
  );
}
