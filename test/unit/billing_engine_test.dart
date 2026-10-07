import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_engine.dart';

void main() {
  group('proratedRent (move-in mid-month)', () {
    test('moving in on the 1st pays the full month', () {
      final rent = proratedRent(20000, '2026-09-01');
      expect(rent.amount, 20000);
      expect(rent.days, isNull);
    });

    test('counts the move-in day and the days left in the month', () {
      final rent = proratedRent(20000, '2026-09-16');
      expect(rent.days!.days, 15);
      expect(rent.days!.of, 30);
      expect(rent.amount, 10000);
    });

    test('uses the real length of the month', () {
      expect(proratedRent(28000, '2027-02-15').amount, 14000); // 14 of 28
      expect(proratedRent(31000, '2026-10-31').amount, 1000); // 1 of 31
    });

    test('rounds to whole shillings', () {
      expect(proratedRent(25000, '2026-10-20').amount, 9677); // 12 of 31
    });
  });
}
