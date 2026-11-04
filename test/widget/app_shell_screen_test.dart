import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/core/services/pdf_document_service.dart';
import 'package:prop_mgt_app/features/messages/domain/models/chat_message.dart';
import 'package:prop_mgt_app/features/messages/presentation/state/messages_providers.dart';
import '../helpers/unlocked_app.dart';

void main() {
  setUp(() {
    PdfDocumentService.useGoogleFonts = false;
    PdfDocumentService.sharePdf = ({required bytes, required filename}) async =>
        true;
  });

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
      await tester.pumpAndSettle();
      expect(find.text('Receipt PDF ready'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.chevron_left_rounded);
      expect(backButton, findsOneWidget);
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Receipts'), findsOneWidget);

      // Statement view and PDF download
      await tester.tap(find.byKey(const ValueKey('open_statement')));
      await tester.pumpAndSettle();
      expect(find.text('Statement'), findsOneWidget);
      expect(find.text('TOTAL BILLED'), findsOneWidget);
      final downloadStatementBtn = find.text('Download PDF');
      expect(downloadStatementBtn, findsOneWidget);
      await tester.ensureVisible(downloadStatementBtn);
      await tester.pumpAndSettle();
      await tester.tap(downloadStatementBtn);
      await tester.pumpAndSettle();
      expect(find.text('Statement PDF ready'), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

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

  testWidgets(
    'AppShellScreen shows notification banner when new incoming message arrives on non-messages tab',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(unlockedApp());
      await tester.pumpAndSettle();

      // We are on Home tab
      expect(find.text('Habari, David'), findsOneWidget);

      // Simulate incoming message from manager
      final element = tester.element(find.byType(PropMgtApp));
      final container = ProviderScope.containerOf(element);
      container
          .read(messagesProvider.notifier)
          .receiveIncomingMessage(
            const ChatMessage(
              id: 'test-manager-msg-1',
              text: 'Water meter reading has been verified.',
              isUserMessage: false,
              timestamp: 'Just now',
            ),
          );
      await tester.pumpAndSettle();

      // Notification banner should appear with message text and Reply action
      expect(find.text('Message from HarborRidge Limited'), findsOneWidget);
      expect(
        find.text('Water meter reading has been verified.'),
        findsOneWidget,
      );
      expect(find.text('Reply'), findsOneWidget);

      // Tapping Reply navigates directly to Messages tab
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      expect(find.text('Njoki Kariuki'), findsOneWidget);
      expect(find.text('Property manager · HarborRidge'), findsOneWidget);
    },
  );
}
