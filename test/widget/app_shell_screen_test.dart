import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';

void main() {
  testWidgets(
    'AppShellScreen renders Home tab and allows navigation between tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: PropMgtApp()));
      await tester.pumpAndSettle();

      expect(find.text('Habari, David'), findsOneWidget);
      expect(find.text('Balance due'), findsOneWidget);
      expect(find.text('KES 45,000'), findsWidgets);
      expect(find.text('Pay rent'), findsOneWidget);

      final paymentsTab = find.text('Payments');
      expect(paymentsTab, findsOneWidget);
      await tester.tap(paymentsTab);
      await tester.pumpAndSettle();

      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Paid in 2026'), findsOneWidget);
      expect(find.text('KES 855,000'), findsOneWidget);
      expect(find.text('RECEIPTS'), findsOneWidget);

      final firstReceipt = find.text('RCT-2610-0416');
      expect(firstReceipt, findsOneWidget);
      await tester.tap(firstReceipt);
      await tester.pumpAndSettle();

      expect(find.text('Receipt'), findsWidgets);
      expect(find.text('Jengo Property Management'), findsOneWidget);
      expect(find.text('KRA PIN P051234567X'), findsOneWidget);
      final downloadBtn = find.text('Download PDF');
      expect(downloadBtn, findsOneWidget);
      await tester.ensureVisible(downloadBtn);
      await tester.pumpAndSettle();
      await tester.tap(downloadBtn);
      await tester.pump();
      expect(find.text('Downloading receipt RCT-2610-0416...'), findsOneWidget);
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.chevron_left_rounded);
      expect(backButton, findsOneWidget);
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('RECEIPTS'), findsOneWidget);

      final repairsTab = find.text('Repairs').last;
      await tester.tap(repairsTab);
      await tester.pumpAndSettle();

      expect(find.text('Repairs'), findsWidgets);
      expect(find.text('New request'), findsOneWidget);
      expect(find.text('Socket in bedroom sparks'), findsOneWidget);

      final messagesTab = find.text('Messages').last;
      await tester.tap(messagesTab);
      await tester.pumpAndSettle();

      expect(find.text('Njoki Kariuki'), findsOneWidget);
      expect(find.text('Property manager · Jengo'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    },
  );
}
