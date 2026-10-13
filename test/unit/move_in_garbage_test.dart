import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_engine.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';

BillingSeed _seedWithMoveInGarbage({int? moveInGarbage}) {
  final json =
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>;
  json['asOf'] = '2026-10-10';
  ((json['tenancies'] as List).single as Map<String, dynamic>)
    ..['moveIn'] = '2026-10-10'
    ..['leaseStart'] = '2026-10-10'
    ..['openingBalance'] = 0
    ..['openingReading'] = 100
    ..['moveInGarbage'] = moveInGarbage;
  json['meterReadings'] = <String, dynamic>{};
  json['repairTickets'] = <dynamic>[];
  json['payments'] = <dynamic>[];
  return BillingSeed.fromJson(json);
}

void main() {
  group('Move-in garbage fee customization', () {
    test('when moveInGarbage is 0, no garbage is charged on move-in bill', () {
      final seed = _seedWithMoveInGarbage(moveInGarbage: 0);
      final bills = BillingEngine(seed).ledger(seed.tenancies.single);
      final moveInBill = bills.firstWhere((b) => b.kind == BillKind.moveIn);

      expect(moveInBill.garbage, 0);
      expect(
        moveInBill.lines.any((l) => l.kind == BillLineKind.garbage),
        isFalse,
      );
      expect(moveInBill.totalDue, moveInBill.deposit + moveInBill.rent);
    });

    test(
      'when moveInGarbage is set to custom amount, it is charged on move-in bill',
      () {
        final seed = _seedWithMoveInGarbage(moveInGarbage: 150);
        final bills = BillingEngine(seed).ledger(seed.tenancies.single);
        final moveInBill = bills.firstWhere((b) => b.kind == BillKind.moveIn);

        expect(moveInBill.garbage, 150);
        expect(moveInBill.totalDue, moveInBill.deposit + moveInBill.rent + 150);
      },
    );

    test('when moveInGarbage is null, defaults to 0 (no fallback)', () {
      final seed = _seedWithMoveInGarbage(moveInGarbage: null);
      final bills = BillingEngine(seed).ledger(seed.tenancies.single);
      final moveInBill = bills.firstWhere((b) => b.kind == BillKind.moveIn);

      expect(moveInBill.garbage, 0);
      expect(
        moveInBill.lines.any((l) => l.kind == BillLineKind.garbage),
        isFalse,
      );
      expect(moveInBill.totalDue, moveInBill.deposit + moveInBill.rent);
    });
  });
}
