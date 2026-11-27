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
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_state.dart';
import '../helpers/unlocked_app.dart';

void main() {
  testWidgets('Pay rent shows where to pay and sends the confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(unlockedApp());
    await tester.pumpAndSettle();

    // Home shows the October bill with September's unpaid water carried in.
    expect(find.text('KES 18,950'), findsWidgets);
    expect(find.text('October bill'), findsOneWidget);
    expect(find.text('Arrears from September'), findsOneWidget);
    expect(find.text('Includes KES 1,450 arrears'), findsOneWidget);
    expect(find.text('KES 1,450'), findsOneWidget);
    expect(find.text('KES 15,000 paid of KES 33,950'), findsOneWidget);
    // Due on the 5th; on 6 Oct the tenant is inside the grace period.
    expect(find.text('Grace period to 20 Oct'), findsOneWidget);

    await tester.tap(find.text('Pay rent'));
    await tester.pumpAndSettle();

    expect(find.text('Balance due KES 18,950'), findsOneWidget);
    expect(find.text('522533'), findsOneWidget);
    expect(find.text('RC-5A'), findsOneWidget);
    expect(find.text('NCBA Bank, Westlands'), findsOneWidget);
    expect(find.text('Copy payment details'), findsOneWidget);
    expect(find.text('Send for confirmation'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('pay_rent_message')),
      'UKA1D18L3S Confirmed. Ksh18,950.00 sent to HARBORRIDGE for account '
      'RC-5A on 6/10/26 at 10:30 AM',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('pay_rent_send')));
    await tester.tap(find.byKey(const ValueKey('pay_rent_send')));
    await tester.pumpAndSettle();
    expect(find.text('Sent for confirmation'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pay_rent_done')));
    await tester.pumpAndSettle();

    // Waits for the manager; the bill is unchanged until they confirm.
    expect(find.byKey(const ValueKey('payment_claims_card')), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('KES 15,000 paid of KES 33,950'), findsOneWidget);
  });

  testWidgets('Pay rent shows fixed bank paybill details without unit code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final base = BillingSeed.fromJson(
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>,
    );
    final baseCompany = base.companies.first;
    final fixedSeed = BillingSeed(
      asOf: base.asOf,
      companies: [
        Company(
          id: baseCompany.id,
          slug: baseCompany.slug,
          name: baseCompany.name,
          kraPin: baseCompany.kraPin,
          mpesaPaybill: '222111',
          bankName: 'THE PHOENIX',
          bankAccount: '404020',
          settings: CompanySettings(
            ledgerStartMonth: baseCompany.settings.ledgerStartMonth,
            dueDay: baseCompany.settings.dueDay,
            graceDay: baseCompany.settings.graceDay,
            depositSchedule: baseCompany.settings.depositSchedule,
            recordRetentionMonths: baseCompany.settings.recordRetentionMonths,
            theme: baseCompany.settings.theme,
            paybillAccountMode: 'bank',
          ),
          receiptSequence: baseCompany.receiptSequence,
          repairTicketSequence: baseCompany.repairTicketSequence,
          subscription: baseCompany.subscription,
        ),
      ],
      properties: base.properties,
      units: base.units,
      tenants: base.tenants,
      tenancies: base.tenancies,
      meterReadings: base.meterReadings,
      payments: base.payments,
      staff: base.staff,
      repairTickets: base.repairTickets,
      messages: base.messages,
    );
    final fixedAccount = TenantAccountState.fromSeed(fixedSeed);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => AuthNotifier(initialStage: AuthStage.unlocked),
          ),
          tenantAccountProvider.overrideWithBuild(
            (ref, notifier) => fixedAccount,
          ),
        ],
        child: const PropMgtApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay rent'));
    await tester.pumpAndSettle();

    final details = find.byKey(const ValueKey('pay_rent_details'));
    expect(details, findsOneWidget);
    expect(
      find.descendant(of: details, matching: find.text('222111')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: details, matching: find.text('404020')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: details, matching: find.text('THE PHOENIX')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: details, matching: find.text('RC-5A')),
      findsNothing,
    );
  });
}
