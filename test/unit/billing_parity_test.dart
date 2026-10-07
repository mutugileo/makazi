import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_engine.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';

// The admin (TypeScript) and the app (Dart) each implement the billing rules.
// shared/billing-expected.json is produced by the TypeScript engine; this test
// fails as soon as the Dart engine disagrees on any bill in the portfolio.

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final seed = BillingSeed.fromJson(_readJson('shared/billing-seed.json'));
  final expected = _readJson('shared/billing-expected.json');
  final engine = BillingEngine(seed);

  test('every tenancy in the fixture is covered', () {
    expect(seed.tenancies.map((t) => t.id).toSet(), expected.keys.toSet());
  });

  for (final tenancy in seed.tenancies) {
    test('Dart engine matches TypeScript engine for ${tenancy.id}', () {
      final bills = engine.ledger(tenancy);
      final want = (expected[tenancy.id] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(bills.length, want.length);
      for (var i = 0; i < bills.length; i++) {
        final b = bills[i];
        final w = want[i];
        final actual = {
          'month': b.month,
          'kind': b.kind.wire,
          'rent': b.rent,
          'rentDays': b.rentDays?.days,
          'waterUnits': b.water?.units,
          'water': b.waterAmount,
          'garbage': b.garbage,
          'deposit': b.deposit,
          'depositApplied': b.depositApplied,
          'depositRefund': b.depositRefund,
          'balanceBf': b.balanceBf,
          'newCharges': b.newCharges,
          'totalDue': b.totalDue,
          'amountPaid': b.amountPaid,
          'outstanding': b.outstanding,
          'status': b.status.label,
          'datePaid': b.datePaid,
        };
        expect(actual, w, reason: '${tenancy.id} ${b.month}');
      }
    });
  }

  for (final entry in kTenantSeedsByPhone.entries) {
    test('app slice for ${entry.key} matches the shared seed', () {
      final appSeed = BillingSeed.fromJson(
        jsonDecode(entry.value) as Map<String, dynamic>,
      );
      final tenancy = appSeed.tenancies.single;
      final appBills = BillingEngine(appSeed).ledger(tenancy);
      final sharedTenancy = seed.tenancies.firstWhere(
        (t) => t.id == tenancy.id,
      );
      final sharedBills = engine.ledger(sharedTenancy);
      expect(
        appBills.map((b) => [b.month, b.totalDue, b.amountPaid]).toList(),
        sharedBills.map((b) => [b.month, b.totalDue, b.amountPaid]).toList(),
      );

      final company = appSeed.companies.single;
      final sharedCompany = engine.companyOf(sharedTenancy);
      expect(company.id, sharedCompany.id);
      expect(company.receiptSequence, sharedCompany.receiptSequence);
      expect(company.repairTicketSequence, sharedCompany.repairTicketSequence);

      // Repairs and messages come from the same records the admin shows.
      expect(
        appSeed.repairTickets.map((t) => [t.id, t.status, t.priority]).toList(),
        seed.repairTickets
            .where((t) => t.tenancyId == tenancy.id)
            .map((t) => [t.id, t.status, t.priority])
            .toList(),
      );
      expect(
        appSeed.messages.map((m) => m.id).toList(),
        seed.messages
            .where((m) => m.tenancyId == tenancy.id)
            .map((m) => m.id)
            .toList(),
      );

      // The app only receives its own manager, never other staff.
      final property = appSeed.properties.single;
      expect(appSeed.staff.map((s) => s.id), [property.managerId]);
    });

    test('app slice for ${entry.key} holds one company only', () {
      final appSeed = BillingSeed.fromJson(
        jsonDecode(entry.value) as Map<String, dynamic>,
      );
      final companyId = appSeed.companies.single.id;
      expect(appSeed.properties.map((p) => p.companyId).toSet(), {companyId});
      expect(appSeed.tenants.map((t) => t.companyId).toSet(), {companyId});
      expect(appSeed.staff.map((s) => s.companyId).toSet(), {companyId});
      expect(
        appSeed.repairTickets.map((t) => t.companyId).toSet()
          ..remove(companyId),
        isEmpty,
      );
      expect(
        appSeed.messages.map((m) => m.companyId).toSet()..remove(companyId),
        isEmpty,
      );
      // And no ids that belong to another company in the shared seed.
      final otherCompanyTenancies = seed.tenancies
          .where((t) => engine.companyOf(t).id != companyId)
          .map((t) => t.id)
          .toSet();
      expect(
        appSeed.payments
            .map((p) => p.tenancyId)
            .toSet()
            .intersection(otherCompanyTenancies),
        isEmpty,
      );
    });
  }

  test('companies keep their own rules and numbering', () {
    final hr = seed.companyById('harborridge');
    final sv = seed.companyById('savanna');
    expect(hr.settings.dueDay, 5);
    expect(sv.settings.dueDay, 1);
    expect(sv.settings.graceDay, 10);
    expect(sv.settings.depositSchedule[2], 20000);
    expect(hr.receiptSequence, isNot(sv.receiptSequence));

    final svBill = engine
        .ledger(seed.tenancies.firstWhere((t) => t.id == 'SV-102'))
        .last;
    expect(svBill.dueDate, '2026-10-01');
    expect(svBill.graceDate, '2026-10-10');
  });
}
