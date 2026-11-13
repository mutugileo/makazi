import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/payment_claim.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';
import 'package:prop_mgt_app/core/data/data_mode.dart';
import 'package:prop_mgt_app/core/data/payment_claims_repository.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_providers.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_repository.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_state.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/messages/domain/models/chat_message.dart';
import 'package:prop_mgt_app/features/messages/presentation/state/messages_providers.dart';
import 'package:prop_mgt_app/features/navigation/presentation/state/navigation_providers.dart';
import 'package:prop_mgt_app/features/notifications/domain/tenant_notification.dart';
import 'package:prop_mgt_app/features/notifications/presentation/state/notifications_providers.dart';
import 'package:prop_mgt_app/features/repairs/presentation/state/repairs_providers.dart';

/// The demo tenant's slice, renamed so a test can tell live data from the
/// bundled seed (whose tenant is David).
BillingSeed _liveSeed() {
  final json =
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>;
  final tenant = (json['tenants'] as List).single as Map<String, dynamic>;
  tenant['name'] = 'Wanjiru Kamau';
  return BillingSeed.fromJson(json);
}

/// The slice after the manager confirmed a payment message.
BillingSeed _liveSeedWithPayment(Map<String, dynamic> payment) {
  final json =
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>;
  final tenant = (json['tenants'] as List).single as Map<String, dynamic>;
  tenant['name'] = 'Wanjiru Kamau';
  (json['payments'] as List).add(payment);
  return BillingSeed.fromJson(json);
}

/// The same slice with its repair in progress and a fundi assigned by staff.
BillingSeed _liveSeedWithVisit() {
  final json =
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>;
  final ticket = (json['repairTickets'] as List).first as Map<String, dynamic>
    ..['status'] = 'in_progress'
    ..['resolvedAt'] = null
    ..['assignedTo'] = 'Otieno Fundi Services'
    ..['assignedPhone'] = '+254712345678'
    ..['visitAt'] = '2026-10-09T14:00:00+03:00';
  json['repairTickets'] = [ticket];
  return BillingSeed.fromJson(json);
}

/// Stands in for Supabase: each call takes the next scripted answer.
class _FakeRepository extends SupabaseBillingRepository {
  final fetches = <Completer<BillingSeed>>[];
  bool failWrites = false;
  int ticketsSaved = 0;
  int messagesSaved = 0;
  List<TenantNotification> notifications = [];
  final markedRead = <String>[];

  @override
  Future<List<TenantNotification>> fetchNotifications({
    required String companyId,
    required String tenancyId,
  }) async => notifications;

  @override
  Future<void> markNotificationRead(String id) async {
    if (failWrites) throw Exception('offline');
    markedRead.add(id);
  }

  @override
  Future<void> markAllNotificationsRead({
    required String companyId,
    required String tenancyId,
  }) async {
    if (failWrites) throw Exception('offline');
    for (final n in notifications) {
      if (n.isUnread) markedRead.add(n.id);
    }
  }

  @override
  Future<BillingSeed> fetchTenantSeed({
    bool fullHistory = false,
    int recentMonths = 12,
  }) {
    final completer = Completer<BillingSeed>();
    fetches.add(completer);
    return completer.future;
  }

  @override
  Future<RepairTicketRecord> submitRepairTicket({
    required String companyId,
    required String tenancyId,
    required String unitId,
    required String category,
    required String title,
    required String description,
    required bool hasPhoto,
  }) async {
    if (failWrites) throw Exception('offline');
    ticketsSaved++;
    return RepairTicketRecord(
      id: 'MT-9001',
      companyId: companyId,
      tenancyId: tenancyId,
      unitId: unitId,
      category: category,
      priority: 'medium',
      status: 'open',
      title: title,
      description: description,
      hasPhoto: hasPhoto,
      createdAt: '2026-10-07T10:00:00+03:00',
      resolvedAt: null,
      assignedTo: null,
      resolutionNote: null,
    );
  }

  @override
  Future<MessageRecord> sendMessage({
    required String companyId,
    required String tenancyId,
    required String body,
  }) async {
    if (failWrites) throw Exception('offline');
    messagesSaved++;
    return MessageRecord(
      id: 'db-$messagesSaved',
      companyId: companyId,
      tenancyId: tenancyId,
      sender: 'tenant',
      staffId: null,
      body: body,
      sentAt: '2026-10-07T10:00:00+03:00',
    );
  }
}

/// Stands in for submit_payment_claim: reads the reference and amount the
/// way the database does for an M-Pesa message, or refuses.
class _FakeClaims implements PaymentClaimsRepository {
  final open = <PaymentClaim>[];
  String? refusal;

  @override
  Future<PaymentClaim> submit({
    required String tenancyId,
    required String message,
  }) async {
    if (refusal != null) throw PaymentClaimRefused(refusal!);
    final claim = PaymentClaim(
      id: 'c${open.length + 1}',
      status: PaymentClaimStatus.pending,
      createdAt: '2026-10-07T10:31:00+03:00',
      reference: RegExp(r'^([A-Z0-9]{10}) Confirmed').firstMatch(message)?[1],
      amount: 18950,
    );
    open.insert(0, claim);
    return claim;
  }

  @override
  Future<List<PaymentClaim>> fetchOpen({required String tenancyId}) async =>
      List.of(open);

  @override
  Future<PaymentClaim> updateClaim({
    required String claimId,
    required String message,
  }) async {
    if (refusal != null) throw PaymentClaimRefused(refusal!);
    final updated = PaymentClaim(
      id: claimId,
      status: PaymentClaimStatus.pending,
      createdAt: '2026-10-07T10:35:00+03:00',
      message: message,
      reference: RegExp(r'^([A-Z0-9]{10}) Confirmed').firstMatch(message)?[1],
      amount: 18950,
    );
    final idx = open.indexWhere((c) => c.id == claimId);
    if (idx >= 0) open[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteClaim({required String claimId}) async {
    open.removeWhere((c) => c.id == claimId);
  }
}

class _SignedIn extends AuthNotifier {
  @override
  build() => const AuthState(stage: AuthStage.unlocked, phone: '+254733605118');
}

Future<_FakeRepository> _pumpLiveApp(
  WidgetTester tester, {
  _FakeClaims? claims,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = _FakeRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        liveDataProvider.overrideWithValue(true),
        supabaseBillingRepositoryProvider.overrideWithValue(repo),
        paymentClaimsRepositoryProvider.overrideWithValue(
          claims ?? _FakeClaims(),
        ),
        tenantRealtimeProvider.overrideWith((ref) => null),
        authProvider.overrideWith(_SignedIn.new),
      ],
      child: const PropMgtApp(),
    ),
  );
  await tester.pump();
  return repo;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(PropMgtApp)));

void main() {
  testWidgets('shows a loader, never seed data, until the account loads', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);

    expect(find.byKey(const ValueKey('tenant_data_loading')), findsOneWidget);
    expect(find.textContaining('David'), findsNothing);

    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();

    expect(find.text('Habari, Wanjiru'), findsOneWidget);
    expect(find.textContaining('David'), findsNothing);
  });

  testWidgets('a failed load shows the problem and retries on request', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.completeError(Exception('offline'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tenant_data_error')), findsOneWidget);
    expect(find.textContaining('David'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(repo.fetches, hasLength(2));
    repo.fetches.last.complete(_liveSeed());
    await tester.pumpAndSettle();
    expect(find.text('Habari, Wanjiru'), findsOneWidget);
  });

  testWidgets('an account without a tenancy says so', (tester) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.completeError(const NoTenancyFound());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tenant_data_none')), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('pay rent: paste the message, it waits for the manager', (
    tester,
  ) async {
    final claims = _FakeClaims();
    final repo = await _pumpLiveApp(tester, claims: claims);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();
    final container = _container(tester);
    final tenancyId = container.read(tenantAccountProvider).tenancy.id;

    await tester.tap(find.text('Pay rent'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pay_rent_details')), findsOneWidget);
    expect(find.text('Balance due KES 18,950'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('pay_rent_message')),
      'UKA1D18L3S Confirmed. Ksh18,950.00 sent to HARBORRIDGE for account '
      'RC-5A on 7/10/26 at 10:30 AM',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('pay_rent_send')));
    await tester.tap(find.byKey(const ValueKey('pay_rent_send')));
    await tester.pumpAndSettle();

    expect(find.text('Sent for confirmation'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pay_rent_sent')),
        matching: find.text('KES 18,950 · UKA1D18L3S'),
      ),
      findsOneWidget,
    );
    // Nothing is paid until the manager confirms.
    expect(container.read(tenantAccountProvider).balance, 18950);

    await tester.tap(find.byKey(const ValueKey('pay_rent_done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment_claims_card')), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);

    // The manager confirms: realtime makes the app reread, the payment is
    // on the bill and the message no longer waits.
    claims.open.clear();
    container
      ..invalidate(liveTenantSeedProvider)
      ..invalidate(paymentClaimsProvider);
    await tester.pump();
    repo.fetches.last.complete(
      _liveSeedWithPayment({
        'receiptNumber': 'RCT-2610-0999',
        'tenancyId': tenancyId,
        'amount': 18950,
        'date': '2026-10-07',
        'time': '10:30',
        'method': 'M-Pesa',
        'reference': 'UKA1D18L3S',
      }),
    );
    await tester.pumpAndSettle();
    expect(container.read(tenantAccountProvider).balance, 0);
    expect(find.text('Paid'), findsWidgets);
    expect(find.byKey(const ValueKey('payment_claims_card')), findsNothing);
  });

  testWidgets('pay rent: a refused message says why and stays open', (
    tester,
  ) async {
    final claims = _FakeClaims()..refusal = 'This payment is already recorded';
    final repo = await _pumpLiveApp(tester, claims: claims);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay rent'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('pay_rent_message')),
      'UKA1D18L3S Confirmed. Ksh18,950.00 sent to HARBORRIDGE',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('pay_rent_send')));
    await tester.tap(find.byKey(const ValueKey('pay_rent_send')));
    await tester.pumpAndSettle();

    expect(find.text('This payment is already recorded'), findsOneWidget);
    expect(find.text('Sent for confirmation'), findsNothing);
    expect(find.byKey(const ValueKey('pay_rent_message')), findsOneWidget);
  });

  testWidgets('a message the manager did not confirm shows the reason', (
    tester,
  ) async {
    final claims = _FakeClaims()
      ..open.add(
        const PaymentClaim(
          id: 'c9',
          status: PaymentClaimStatus.rejected,
          createdAt: '2026-10-06T09:00:00+03:00',
          reference: 'QWE1RTY2UI',
          amount: 5000,
          reviewNote: 'No such payment on our statement',
        ),
      );
    final repo = await _pumpLiveApp(tester, claims: claims);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();

    expect(find.text('Not confirmed'), findsOneWidget);
    expect(
      find.text('Not confirmed: No such payment on our statement'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('claim_edit_c9')), findsOneWidget);
    expect(find.byKey(const ValueKey('claim_delete_c9')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('claim_delete_c9')));
    await tester.tap(find.byKey(const ValueKey('claim_delete_c9')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment_claims_card')), findsNothing);
  });

  testWidgets('an assigned repair shows who is coming, their number and when', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.complete(_liveSeedWithVisit());
    await tester.pumpAndSettle();
    _container(tester).read(navigationProvider.notifier).navigateToRepairs();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('repair_visit_panel')), findsOneWidget);
    expect(find.text('Otieno Fundi Services'), findsOneWidget);
    expect(find.text('0712 345 678'), findsOneWidget);
    expect(find.text('Visit Fri 9 Oct, 2:00 pm'), findsOneWidget);
    expect(find.byKey(const ValueKey('repair_visit_call')), findsOneWidget);
  });

  testWidgets('a repair request that fails to save keeps the form open', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();
    final container = _container(tester);
    container.read(navigationProvider.notifier).navigateToRepairs();
    await tester.pumpAndSettle();

    final repairs = container.read(repairsProvider.notifier);
    repairs.openNewRequest();
    repairs.updateDescription('Kitchen tap is leaking');
    repo.failWrites = true;
    await repairs.submitRequest();
    await tester.pumpAndSettle();

    final state = container.read(repairsProvider);
    expect(state.isNewRequestOpen, isTrue);
    expect(state.newlyCreatedTicket, isNull);
    expect(find.byKey(const ValueKey('repair_submit_error')), findsOneWidget);

    // Saved on retry: the ticket carries the database's number.
    repo.failWrites = false;
    final submitting = repairs.submitRequest();
    await tester.pump();
    repo.fetches.last.complete(_liveSeed());
    await submitting;
    await tester.pump();
    expect(repo.ticketsSaved, 1);
    expect(find.text('Request MT-9001 submitted'), findsOneWidget);
    expect(container.read(repairsProvider).isNewRequestOpen, isFalse);
  });

  testWidgets('a message that fails to send is marked and can be retried', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();
    final container = _container(tester);
    final messages = container.read(messagesProvider.notifier);

    repo.failWrites = true;
    await messages.dispatchUserMessage('Is water off today?');
    expect(
      container.read(messagesProvider).last.delivery,
      MessageDelivery.failed,
    );

    repo.failWrites = false;
    final retrying = messages.retry(container.read(messagesProvider).last.id);
    await tester.pump();
    repo.fetches.last.complete(_liveSeed());
    await retrying;
    final last = container.read(messagesProvider).last;
    expect(repo.messagesSaved, 1);
    expect(last.text, 'Is water off today?');
    expect(last.delivery, MessageDelivery.sent);
  });

  testWidgets('a payment reminder shows on Home until dismissed', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.notifications = [
      const TenantNotification(
        id: 'n1',
        kind: 'payment_reminder',
        title: 'Payment reminder from HarborRidge Limited',
        body: 'Habari Wanjiru, your balance is KES 18,950.',
        createdAt: '2026-10-07T09:12:00+03:00',
      ),
    ];
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notification_n1')), findsOneWidget);
    expect(
      find.text('Payment reminder from HarborRidge Limited'),
      findsOneWidget,
    );
    // Already there when the app opened: no drop-down as well.
    expect(find.byType(MaterialBanner), findsNothing);

    // Dismissing waits for the database; a failure keeps the card.
    repo.failWrites = true;
    await tester.tap(find.byKey(const ValueKey('notification_dismiss_n1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification_n1')), findsOneWidget);
    expect(find.textContaining('Couldn\'t dismiss'), findsOneWidget);

    repo.failWrites = false;
    await tester.tap(find.byKey(const ValueKey('notification_dismiss_n1')));
    await tester.pumpAndSettle();
    expect(repo.markedRead, ['n1']);
    expect(find.byKey(const ValueKey('notification_n1')), findsNothing);
  });

  testWidgets('a reminder that arrives while the app is open drops down', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);

    // The admin sends one; realtime makes the app refetch.
    repo.notifications = [
      const TenantNotification(
        id: 'n2',
        kind: 'payment_reminder',
        title: 'Payment reminder from HarborRidge Limited',
        body: 'Habari Wanjiru, please pay by 20 Oct.',
        createdAt: '2026-10-07T10:00:00+03:00',
      ),
    ];
    _container(tester).invalidate(tenantNotificationsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('notification_banner_n2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('notification_n2')), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification_banner_n2')), findsNothing);
    expect(find.byKey(const ValueKey('notification_n2')), findsOneWidget);
  });
}
