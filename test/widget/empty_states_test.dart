import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_notifier.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_state.dart';
import 'package:prop_mgt_app/features/navigation/presentation/state/navigation_providers.dart';

/// A tenant onboarded today who moves in on 1 November: no bills, payments,
/// repairs or messages yet.
class _NewTenantAccount extends TenantAccountNotifier {
  @override
  TenantAccountState build() {
    final json =
        jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
            as Map<String, dynamic>;
    final tenancy = (json['tenancies'] as List).single as Map<String, dynamic>;
    tenancy
      ..['moveIn'] = '2026-11-01'
      ..['leaseStart'] = '2026-11-01'
      ..['openingBalance'] = 0
      ..['renewal'] = null;
    json
      ..['payments'] = <dynamic>[]
      ..['repairTickets'] = <dynamic>[]
      ..['messages'] = <dynamic>[];
    return TenantAccountState.fromSeed(BillingSeed.fromJson(json));
  }
}

void main() {
  testWidgets('a brand-new tenant sees helpful empty states, not errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => AuthNotifier(initialStage: AuthStage.unlocked),
          ),
          tenantAccountProvider.overrideWith(_NewTenantAccount.new),
        ],
        child: const PropMgtApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final nav = container.read(navigationProvider.notifier);

    // Home
    expect(find.text('New'), findsOneWidget);
    expect(find.text('No bill yet'), findsOneWidget);
    expect(find.text('First bill 1 Nov'), findsOneWidget);
    expect(find.text('Nothing due'), findsOneWidget);
    expect(find.text('No payments yet'), findsOneWidget);

    // Payments: bills and receipts
    nav.navigateToPayments();
    await tester.pumpAndSettle();
    expect(find.text('No bills yet'), findsOneWidget);
    await tester.tap(find.text('Receipts'));
    await tester.pumpAndSettle();
    expect(find.text('No payments yet'), findsOneWidget);

    // Repairs
    nav.navigateToRepairs();
    await tester.pumpAndSettle();
    expect(find.text('No repair requests yet'), findsOneWidget);
    expect(find.text('New request'), findsOneWidget);

    // Messages
    nav.navigateToMessages();
    await tester.pumpAndSettle();
    expect(find.text('No messages yet'), findsOneWidget);
    expect(
      find.text('Ask Njoki Kariuki anything about your home.'),
      findsOneWidget,
    );
  });
}
