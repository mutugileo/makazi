import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/widgets/bill_breakdown.dart';
import 'package:prop_mgt_app/features/payments/presentation/widgets/bill_detail_view.dart';

void main() {
  group('Water billing UI tests', () {
    testWidgets('shows Pending water bill when water is not set on a monthly bill', (tester) async {
      const billWithoutWater = MonthlyBill(
        tenancyId: 'tenancy_1',
        month: '2026-11',
        kind: BillKind.monthly,
        dueDate: '2026-11-05',
        graceDate: '2026-11-10',
        rentDays: null,
        lines: [
          BillLine(kind: BillLineKind.rent, amount: 45000),
          BillLine(kind: BillLineKind.garbage, amount: 200),
        ],
        water: null,
        balanceBf: 0,
        amountPaid: 0,
        payments: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillBreakdown(bill: billWithoutWater),
          ),
        ),
      );

      expect(find.text('Pending water bill'), findsOneWidget);
      expect(find.text('Reading pending from management'), findsOneWidget);
      expect(find.text('KES 45,200'), findsNWidgets(2)); // Total due and Outstanding

      // Check BillDetailView notice
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillDetailView(
              bill: billWithoutWater,
              receipts: const [],
              onBackPressed: () {},
              onReceiptSelected: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Pending water bill · Monthly meter reading will be added'),
        findsOneWidget,
      );
    });

    testWidgets('includes water in lines and total when water bill is set', (tester) async {
      const billWithWater = MonthlyBill(
        tenancyId: 'tenancy_1',
        month: '2026-10',
        kind: BillKind.monthly,
        dueDate: '2026-10-05',
        graceDate: '2026-10-10',
        rentDays: null,
        lines: [
          BillLine(kind: BillLineKind.rent, amount: 45000),
          BillLine(kind: BillLineKind.water, amount: 1200),
          BillLine(kind: BillLineKind.garbage, amount: 200),
        ],
        water: WaterUsage(
          previousReading: 100,
          currentReading: 108,
          units: 8,
          rate: 150,
        ),
        balanceBf: 0,
        amountPaid: 0,
        payments: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillBreakdown(bill: billWithWater),
          ),
        ),
      );

      expect(find.text('Pending water bill'), findsNothing);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('8 units × KES 150'), findsOneWidget);
      expect(find.text('KES 1,200'), findsOneWidget);
      expect(find.text('KES 46,400'), findsNWidgets(2)); // Total due and Outstanding (45000 + 1200 + 200)

      // Check BillDetailView meter reading card
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillDetailView(
              bill: billWithWater,
              receipts: const [],
              onBackPressed: () {},
              onReceiptSelected: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Meter 100 → 108 · 8 units used in September'),
        findsOneWidget,
      );
    });
  });
}
