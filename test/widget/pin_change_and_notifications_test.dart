import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';
import 'package:prop_mgt_app/core/data/data_mode.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_providers.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_repository.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_state.dart';
import 'package:prop_mgt_app/features/auth/presentation/widgets/change_pin_sheet.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_state.dart';
import 'package:prop_mgt_app/features/home/presentation/screens/home_screen.dart';
import 'package:prop_mgt_app/features/home/presentation/widgets/account_sheet.dart';
import 'package:prop_mgt_app/features/notifications/domain/tenant_notification.dart';
import 'package:prop_mgt_app/features/notifications/presentation/screens/notifications_screen.dart';

class _FakeBillingRepository extends SupabaseBillingRepository {
  List<TenantNotification> notifications = [];
  final markedRead = <String>[];
  bool allMarkedRead = false;

  @override
  Future<List<TenantNotification>> fetchNotifications({
    required String companyId,
    required String tenancyId,
  }) async => notifications;

  @override
  Future<void> markNotificationRead(String id) async {
    markedRead.add(id);
  }

  @override
  Future<void> markAllNotificationsRead({
    required String companyId,
    required String tenancyId,
  }) async {
    allMarkedRead = true;
    for (final n in notifications) {
      markedRead.add(n.id);
    }
  }

  @override
  Future<BillingSeed> fetchTenantSeed({
    bool fullHistory = false,
    int recentMonths = 12,
  }) async {
    return BillingSeed.fromJson(
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>,
    );
  }
}

class _MockAuthNotifier extends AuthNotifier {
  String? lastCurrentPin;
  String? lastNewPin;
  String? lastConfirmation;

  @override
  AuthState build() =>
      const AuthState(stage: AuthStage.unlocked, phone: '+254733605118');

  @override
  Future<String?> changePin({
    required String currentPin,
    required String newPin,
    required String confirmation,
  }) async {
    lastCurrentPin = currentPin;
    lastNewPin = newPin;
    lastConfirmation = confirmation;
    return null;
  }
}

void main() {
  testWidgets('ChangePinSheet validates inputs and submits new 4-digit PIN', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockAuth = _MockAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => mockAuth)],
        child: const MaterialApp(home: Scaffold(body: ChangePinSheet())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change 4-digit PIN'), findsOneWidget);
    expect(find.byKey(const ValueKey('change_pin_current')), findsOneWidget);
    expect(find.byKey(const ValueKey('change_pin_new')), findsOneWidget);
    expect(find.byKey(const ValueKey('change_pin_confirm')), findsOneWidget);

    // Try submit empty:
    await tester.tap(find.byKey(const ValueKey('change_pin_submit_button')));
    await tester.pump();
    expect(find.text('Enter your current 4-digit PIN'), findsOneWidget);

    // Enter current pin only:
    await tester.enterText(
      find.byKey(const ValueKey('change_pin_current')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('change_pin_submit_button')));
    await tester.pump();
    expect(find.text('Enter your new 4-digit PIN'), findsOneWidget);

    // Enter mismatching new pins:
    await tester.enterText(
      find.byKey(const ValueKey('change_pin_new')),
      '5678',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change_pin_confirm')),
      '9999',
    );
    await tester.tap(find.byKey(const ValueKey('change_pin_submit_button')));
    await tester.pump();
    expect(find.text('The new PINs do not match'), findsOneWidget);

    // Enter matching new pin and submit:
    await tester.enterText(
      find.byKey(const ValueKey('change_pin_confirm')),
      '5678',
    );
    await tester.tap(find.byKey(const ValueKey('change_pin_submit_button')));
    await tester.pump();

    expect(mockAuth.lastCurrentPin, '1234');
    expect(mockAuth.lastNewPin, '5678');
    expect(mockAuth.lastConfirmation, '5678');
  });

  testWidgets(
    'NotificationsScreen displays PIN reset notification with 72h validity and Change PIN action',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepository();
      final seed = await repo.fetchTenantSeed();
      repo.notifications = [
        const TenantNotification(
          id: 'notif-pin-1',
          kind: 'payment_reminder',
          title: 'Security: New 4-digit PIN generated',
          body:
              'Your Makazi login PIN is 4920. Valid for 72 hours. Please change your PIN once logged in.',
          createdAt: '2026-10-20T10:00:00+03:00',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(true),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Notifications'), findsOneWidget);
      expect(find.text('Security: New 4-digit PIN generated'), findsOneWidget);
      expect(find.textContaining('Valid for 72 hours'), findsWidgets);
      expect(
        find.byKey(const ValueKey('notification_change_pin_notif-pin-1')),
        findsOneWidget,
      );

      // Tap Change PIN: opens ChangePinSheet
      await tester.tap(
        find.byKey(const ValueKey('notification_change_pin_notif-pin-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a new PIN for this phone'), findsOneWidget);
    },
  );

  testWidgets('NotificationsScreen mark all read marks all unread items read', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeBillingRepository();
    final seed = await repo.fetchTenantSeed();
    repo.notifications = [
      const TenantNotification(
        id: 'n-1',
        kind: 'payment_reminder',
        title: 'Notice 1',
        body: 'First notice',
        createdAt: '2026-10-20T10:00:00+03:00',
      ),
      const TenantNotification(
        id: 'n-2',
        kind: 'payment_reminder',
        title: 'Notice 2',
        body: 'Second notice',
        createdAt: '2026-10-20T11:00:00+03:00',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveDataProvider.overrideWithValue(true),
          supabaseBillingRepositoryProvider.overrideWithValue(repo),
          liveTenantSeedProvider.overrideWith((ref) => seed),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications (2)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notifications_mark_all_read')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('notifications_mark_all_read')));
    await tester.pumpAndSettle();

    expect(repo.allMarkedRead, isTrue);
    expect(repo.markedRead, containsAll(['n-1', 'n-2']));
  });

  testWidgets(
    'AccountSheet provides actions to Change 4-digit PIN and open Notifications',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepository();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(true),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountSheet(account: refAccountStateFromSeed(seed)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('account_change_pin_tile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account_notifications_tile')),
        findsOneWidget,
      );
      expect(find.text('Change 4-digit PIN'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen header contains notifications bell that navigates to NotificationsScreen',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepository();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(true),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('home_notifications_bell')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('home_notifications_bell')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('notifications_screen')),
        findsOneWidget,
      );
    },
  );
}

TenantAccountState refAccountStateFromSeed(BillingSeed seed) {
  return TenantAccountState.fromSeed(seed);
}
