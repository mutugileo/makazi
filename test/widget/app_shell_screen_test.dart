import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/unlocked_app.dart';

void main() {
  testWidgets(
    'AppShellScreen renders Home tab and allows navigation between tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(unlockedApp());
      await tester.pumpAndSettle();

      expect(find.text('Habari, David'), findsOneWidget);
      expect(find.text('Riverside Court · 5A'), findsOneWidget);
      expect(find.text('Balance due'), findsOneWidget);
      expect(find.text('KES 18,950'), findsWidgets);
      expect(find.text('Pay rent'), findsOneWidget);

      final paymentsTab = find.text('Payments');
      expect(paymentsTab, findsOneWidget);
      await tester.tap(paymentsTab);
      await tester.pumpAndSettle();

      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Paid since May'), findsOneWidget);
      expect(find.text('KES 173,200'), findsOneWidget);
      expect(find.text('KES 30,000'), findsOneWidget, reason: 'deposit held');

      // Bills list, newest first, with spreadsheet-style statuses.
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Partial'), findsNWidgets(2));
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('15 units × KES 150'), findsOneWidget);
      expect(find.text('Balance from September'), findsOneWidget);
      expect(find.textContaining('units used in September'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Receipts'));
      await tester.pumpAndSettle();
      final firstReceipt = find.text('RCT-2610-0373 · 02 Oct 2026');
      expect(firstReceipt, findsOneWidget);
      await tester.tap(firstReceipt);
      await tester.pumpAndSettle();

      expect(find.text('Receipt'), findsWidgets);
      expect(find.text('HarborRidge Limited'), findsOneWidget);
      expect(find.text('KRA PIN P051234567X'), findsOneWidget);
      final downloadBtn = find.text('Download PDF');
      expect(downloadBtn, findsOneWidget);
      await tester.ensureVisible(downloadBtn);
      await tester.pumpAndSettle();
      await tester.tap(downloadBtn);
      await tester.pump();
      expect(
        find.text(
          'PDF receipts not available yet. They arrive with the database.',
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.chevron_left_rounded);
      expect(backButton, findsOneWidget);
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Receipts'), findsOneWidget);

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
      expect(find.text('Property manager · HarborRidge'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    },
  );
}
