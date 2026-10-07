import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/unlocked_app.dart';

void main() {
  testWidgets('Pay rent pays the outstanding bill and settles Home', (
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
    expect(find.text('Balance from September'), findsOneWidget);
    expect(find.text('KES 1,450'), findsOneWidget);
    expect(find.text('KES 15,000 paid of KES 33,950'), findsOneWidget);
    // Due on the 5th; on 6 Oct the tenant is inside the grace period.
    expect(find.text('Grace period to 20 Oct'), findsOneWidget);

    await tester.tap(find.text('Pay rent'));
    await tester.pumpAndSettle();

    expect(find.text('18,950'), findsOneWidget);
    expect(find.text('Full balance · KES 18,950'), findsOneWidget);
    expect(find.text('Other amount'), findsOneWidget);
    expect(find.text('0733 605 118'), findsOneWidget);
    expect(
      find.text('STK push to your phone · Paybill 522533 · Account RC-5A'),
      findsOneWidget,
    );

    await tester.tap(find.text('Other amount'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount to pay'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('pay_rent_other_amount')),
      '20000',
    );
    await tester.pumpAndSettle();
    expect(find.text('20,000'), findsOneWidget);
    expect(find.text('Pay KES 20,000'), findsOneWidget);

    await tester.tap(find.text('Full balance · KES 18,950'));
    await tester.pumpAndSettle();
    expect(find.text('Pay KES 18,950'), findsOneWidget);

    await tester.tap(find.text('Bank transfer'));
    await tester.pumpAndSettle();
    expect(find.text('NCBA Bank, Westlands'), findsOneWidget);
    expect(find.text('1004  5582  31'), findsOneWidget);
    expect(find.text('RC-5A'), findsOneWidget);
    expect(find.text('Copy bank details'), findsOneWidget);

    await tester.tap(find.text('M-Pesa'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay KES 18,950'));
    await tester.pump();
    expect(find.text('Confirming payment'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('KES 18,950'), findsOneWidget);
    expect(find.textContaining('RCT-2610-0380 · '), findsOneWidget);

    await tester.tap(find.text('View receipt'));
    await tester.pumpAndSettle();
    expect(find.text('HarborRidge Limited'), findsOneWidget);
    expect(find.text('RCT-2610-0380'), findsOneWidget);
    expect(find.text('Bill, October 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Habari, David'), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('KES 0'), findsWidgets);
    expect(find.text('Nothing due'), findsOneWidget);
  });
}
