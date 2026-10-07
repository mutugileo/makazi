import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';
import 'package:prop_mgt_app/core/data/data_mode.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_providers.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_repository.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_state.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/home/presentation/state/home_pay_rent_providers.dart';
import 'package:prop_mgt_app/features/messages/domain/models/chat_message.dart';
import 'package:prop_mgt_app/features/messages/presentation/state/messages_providers.dart';
import 'package:prop_mgt_app/features/navigation/presentation/state/navigation_providers.dart';
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

/// Stands in for Supabase: each call takes the next scripted answer.
class _FakeRepository extends SupabaseBillingRepository {
  final fetches = <Completer<BillingSeed>>[];
  bool failWrites = false;
  int ticketsSaved = 0;
  int messagesSaved = 0;

  @override
  Future<BillingSeed> fetchTenantSeed() {
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

class _SignedIn extends AuthNotifier {
  @override
  build() => const AuthState(stage: AuthStage.unlocked, phone: '+254733605118');
}

Future<_FakeRepository> _pumpLiveApp(WidgetTester tester) async {
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
        tenantRealtimeProvider.overrideWith((ref) {}),
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

  testWidgets('pay rent shows Paybill details and never records a payment', (
    tester,
  ) async {
    final repo = await _pumpLiveApp(tester);
    repo.fetches.single.complete(_liveSeed());
    await tester.pumpAndSettle();
    final container = _container(tester);
    final receiptsBefore = container
        .read(tenantAccountProvider)
        .receipts
        .length;

    container.read(homePayRentProvider.notifier).openPayRent();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mpesa_paybill_details')), findsOneWidget);
    expect(find.textContaining('STK push'), findsNothing);

    await container.read(homePayRentProvider.notifier).submitPayment();
    expect(
      container.read(tenantAccountProvider).receipts.length,
      receiptsBefore,
    );
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
}
