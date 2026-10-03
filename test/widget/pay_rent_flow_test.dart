import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';

void main() {
  testWidgets('Pay rent flow completes from Home and reveals receipt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PropMgtApp()));
    await tester.pumpAndSettle();

    final payRentBtn = find.text('Pay rent');
    expect(payRentBtn, findsOneWidget);
    await tester.tap(payRentBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pay rent'), findsOneWidget);
    expect(find.text('45000'), findsOneWidget);
    expect(find.text('Full balance · KES 45,000'), findsOneWidget);
    expect(find.text('Half · KES 22,500'), findsOneWidget);
    expect(find.text('M-Pesa'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);

    final halfOption = find.text('Half · KES 22,500');
    await tester.tap(halfOption);
    await tester.pumpAndSettle();

    expect(find.text('22500'), findsOneWidget);
    expect(find.text('Pay KES 22,500'), findsOneWidget);

    final fullOption = find.text('Full balance · KES 45,000');
    await tester.tap(fullOption);
    await tester.pumpAndSettle();

    expect(find.text('45000'), findsOneWidget);
    expect(find.text('Pay KES 45,000'), findsOneWidget);

    final bankTransferCard = find.text('Bank transfer');
    await tester.tap(bankTransferCard);
    await tester.pumpAndSettle();

    expect(find.text('NCBA Bank, Westlands'), findsOneWidget);
    expect(find.text('1004  5582  31'), findsOneWidget);
    expect(find.text('RC-5A'), findsOneWidget);
    expect(find.text('Copy bank details'), findsOneWidget);

    final mpesaCard = find.text('M-Pesa');
    await tester.tap(mpesaCard);
    await tester.pumpAndSettle();

    expect(find.text('0733  605  118'), findsOneWidget);

    final submitBtn = find.text('Pay KES 45,000');
    await tester.tap(submitBtn);
    await tester.pump();

    expect(find.text('Confirming payment'), findsOneWidget);
    expect(
      find.text(
        'Waiting for M-Pesa to confirm. Your receipt will be ready in a moment.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('KES 45,000'), findsOneWidget);
    expect(find.text('RCT-2610-0423 · SJAEEMDE4J'), findsOneWidget);

    final viewReceiptBtn = find.text('View receipt');
    await tester.tap(viewReceiptBtn);
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsWidgets);
    expect(find.text('Jengo Property Management'), findsOneWidget);
    expect(find.text('RCT-2610-0423'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);

    final backBtn = find.byIcon(Icons.chevron_left_rounded);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Payment received'), findsOneWidget);

    final doneBtn = find.text('Done');
    await tester.tap(doneBtn);
    await tester.pumpAndSettle();

    expect(find.text('Habari, David'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('KES 0'), findsOneWidget);
  });
}
