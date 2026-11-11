import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_engine.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';

final _base = BillingSeed.fromJson(
  jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!) as Map<String, dynamic>,
);

/// The demo company and unit with one tenancy moving in after the switch to
/// cycles that start on the 4th.
BillingSeed _seed({
  required String asOf,
  int? moveInRent,
  int? openingReading,
  Map<String, int> readings = const {},
  List<Payment> payments = const [],
}) {
  final tenancy = Tenancy(
    id: 'L-NEW',
    tenantId: _base.tenants.first.id,
    unitId: _base.tenancies.first.unitId,
    rent: 30000,
    deposit: 30000,
    moveIn: '2026-12-10',
    moveOut: null,
    leaseStart: '2026-12-10',
    leaseEnd: '2027-12-09',
    openingBalance: 0,
    openingReading: openingReading,
    renewal: null,
    moveInRent: moveInRent,
  );
  return BillingSeed(
    asOf: asOf,
    companies: _base.companies,
    properties: _base.properties,
    units: _base.units,
    tenants: _base.tenants,
    tenancies: [tenancy],
    meterReadings: {_base.tenancies.first.unitId: readings},
    payments: payments,
    staff: _base.staff,
    repairTickets: const [],
    messages: const [],
  );
}

Payment _paid(String date, int amount) => Payment(
  receiptNumber: 'RCT-$date',
  tenancyId: 'L-NEW',
  amount: amount,
  date: date,
  time: '10:00',
  method: PaymentMethod.mpesa,
  reference: 'REF$amount',
);

List<MonthlyBill> _ledger(BillingSeed seed) =>
    BillingEngine(seed).ledger(seed.tenancies.single);

void main() {
  group('billing cycles', () {
    test('cycles before December 2026 are calendar months', () {
      expect(BillingDates.cycleOf('2026-11-01'), '2026-11');
      expect(BillingDates.cycleOf('2026-11-30'), '2026-11');
      expect(BillingDates.cycleStart('2026-11'), '2026-11-01');
    });

    test('November runs to 3 December; cycles then start on the 4th', () {
      expect(BillingDates.cycleOf('2026-12-03'), '2026-11');
      expect(BillingDates.cycleOf('2026-12-04'), '2026-12');
      expect(BillingDates.cycleOf('2027-01-03'), '2026-12');
      expect(BillingDates.cycleOf('2027-01-04'), '2027-01');
      expect(BillingDates.cycleStart('2027-01'), '2027-01-04');
    });
  });

  group('move-in rent', () {
    test('the landlord sets the move-in rent', () {
      final bill = _ledger(_seed(asOf: '2026-12-20', moveInRent: 15000)).single;
      expect(bill.kind, BillKind.moveIn);
      expect(bill.month, '2026-12');
      expect(bill.rent, 15000);
      expect(bill.deposit, 30000);
    });

    test('none set means a full month', () {
      expect(_ledger(_seed(asOf: '2026-12-20')).single.rent, 30000);
    });
  });

  group('payments and the next bill', () {
    test('the next bill appears on the 4th, not the 1st', () {
      expect(_ledger(_seed(asOf: '2027-01-03', moveInRent: 15000)).length, 1);
      final bills = _ledger(_seed(asOf: '2027-01-04', moveInRent: 15000));
      expect(bills.map((b) => b.month), ['2026-12', '2027-01']);
      expect(bills.last.rent, 30000);
    });

    test('a payment on the 2nd counts towards the cycle it was made in', () {
      final bills = _ledger(
        _seed(
          asOf: '2027-01-04',
          moveInRent: 15000,
          payments: [_paid('2027-01-02', 45000)],
        ),
      );
      expect(bills.first.amountPaid, 45000);
      expect(bills.first.status, BillStatus.paid);
      expect(bills.last.amountPaid, 0);
    });

    test('paying less leaves it partial; paying more carries credit', () {
      final part = _ledger(
        _seed(
          asOf: '2026-12-20',
          moveInRent: 15000,
          payments: [_paid('2026-12-15', 20000)],
        ),
      ).single;
      expect(part.status, BillStatus.partial);
      expect(part.outstanding, 25000);

      final over = _ledger(
        _seed(
          asOf: '2026-12-20',
          moveInRent: 15000,
          payments: [_paid('2026-12-15', 50000)],
        ),
      ).single;
      expect(over.status, BillStatus.credit);
      expect(over.outstanding, -5000);
    });
  });

  group('water', () {
    test('a skipped reading is billed on the next one, never twice', () {
      final bills = _ledger(
        _seed(
          asOf: '2027-02-10',
          openingReading: 0,
          readings: const {'2026-12': 20, '2027-02': 24},
        ),
      );
      expect(bills.map((b) => b.month), ['2026-12', '2027-01', '2027-02']);
      // Move-in cycle: from the move-in reading.
      expect(bills[0].water!.units, 20);
      // No reading in January: nothing billed yet.
      expect(bills[1].water, isNull);
      // February covers everything since December's reading.
      expect(bills[2].water!.previousReading, 20);
      expect(bills[2].water!.units, 4);
    });
  });
}
