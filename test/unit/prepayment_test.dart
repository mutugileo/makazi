import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_engine.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';

/// The demo tenant re-signed to move in next month (1 Nov), with no history,
/// as the live HarborRidge tenant is. [paidOn] adds one payment.
BillingSeed _movingInNextMonth({String? paidOn, int amount = 0}) {
  final json =
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>;
  json['asOf'] = '2026-10-08';
  final tenancy = (json['tenancies'] as List).single as Map<String, dynamic>
    ..['moveIn'] = '2026-11-01'
    ..['leaseStart'] = '2026-11-01'
    ..['openingBalance'] = 0
    ..['openingReading'] = null;
  json['meterReadings'] = <String, dynamic>{};
  json['repairTickets'] = <dynamic>[];
  json['payments'] = [
    if (paidOn != null)
      {
        'receiptNumber': 'RCT-2610-0002',
        'tenancyId': tenancy['id'],
        'amount': amount,
        'date': paidOn,
        'time': '09:15',
        'method': 'M-Pesa',
        'reference': 'SIM4AC86E7',
        'simulated': true,
      },
  ];
  return BillingSeed.fromJson(json);
}

void main() {
  group('paying before the first bill', () {
    test('without a payment, a future tenant has no bill yet', () {
      final seed = _movingInNextMonth();
      final engine = BillingEngine(seed);
      expect(engine.ledger(seed.tenancies.single), isEmpty);
    });

    test('a payment made before move-in counts towards the move-in bill', () {
      // First, what the move-in bill comes to.
      final bare = _movingInNextMonth(paidOn: '2026-10-08', amount: 1);
      final moveInTotal = BillingEngine(
        bare,
      ).ledger(bare.tenancies.single).single.totalDue;

      final seed = _movingInNextMonth(
        paidOn: '2026-10-08',
        amount: moveInTotal,
      );
      final bills = BillingEngine(seed).ledger(seed.tenancies.single);

      expect(bills, hasLength(1));
      final bill = bills.single;
      expect(bill.month, '2026-11');
      expect(bill.kind, BillKind.moveIn);
      expect(bill.amountPaid, moveInTotal);
      expect(bill.outstanding, 0);
      expect(bill.status, BillStatus.paid);
      expect(bill.payments.single.receiptNumber, 'RCT-2610-0002');
    });

    test('a part payment ahead leaves only the rest owing', () {
      final seed = _movingInNextMonth(paidOn: '2026-10-08', amount: 10000);
      final bill = BillingEngine(seed).ledger(seed.tenancies.single).single;
      expect(bill.amountPaid, 10000);
      expect(bill.outstanding, bill.totalDue - 10000);
      expect(bill.status, BillStatus.partial);
    });
  });
}
