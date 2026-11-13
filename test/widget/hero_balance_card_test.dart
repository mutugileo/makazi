import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/features/home/presentation/widgets/hero_balance_card.dart';

MonthlyBill _bill({required int balanceBf}) => MonthlyBill(
  tenancyId: 'L-1',
  month: '2027-02',
  kind: BillKind.monthly,
  dueDate: '2027-02-04',
  graceDate: '2027-02-20',
  lines: const [
    BillLine(kind: BillLineKind.rent, amount: 90000),
    BillLine(kind: BillLineKind.garbage, amount: 250),
  ],
  water: null,
  balanceBf: balanceBf,
  amountPaid: 0,
  payments: const [],
);

Future<void> _pump(WidgetTester tester, MonthlyBill bill) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: HeroBalanceCard(
          bill: bill,
          asOf: '2027-02-04',
          onPayRentPressed: () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('credit from earlier bills is shown as taken off', (
    tester,
  ) async {
    await _pump(tester, _bill(balanceBf: -3000));
    expect(find.text('KES 87,250'), findsOneWidget);
    expect(find.text('After KES 3,000 credit'), findsOneWidget);
  });

  testWidgets('unpaid earlier bills are shown as arrears', (tester) async {
    await _pump(tester, _bill(balanceBf: 91450));
    expect(find.text('KES 181,700'), findsOneWidget);
    expect(find.text('Includes KES 91,450 arrears'), findsOneWidget);
  });

  testWidgets('nothing carried in, no extra line', (tester) async {
    await _pump(tester, _bill(balanceBf: 0));
    expect(find.byKey(const ValueKey('hero_carried_balance')), findsNothing);
  });
}
