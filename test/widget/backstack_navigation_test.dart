import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/shell/presentation/screens/app_shell_screen.dart';

import '../helpers/unlocked_app.dart';

void main() {
  group('Backstack Navigation', () {
    testWidgets('system back from Payments tab navigates back to Home', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(unlockedApp());
      await tester.pumpAndSettle();

      expect(find.text('Habari, David'), findsOneWidget);

      // Tap Payments tab
      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();
      expect(find.text('Payments'), findsWidgets);

      // Trigger system back
      final navigator = Navigator.of(
        tester.element(find.byType(AppShellScreen)),
      );
      final didPop = await navigator.maybePop();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      // Back on Home screen
      expect(find.text('Habari, David'), findsOneWidget);
    });

    testWidgets('system back in Payments closes bill detail before tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(unlockedApp());
      await tester.pumpAndSettle();

      // Tap Payments
      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();

      // Tap a bill
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Water'), findsOneWidget);

      // First back: closes bill detail
      final navigator = Navigator.of(
        tester.element(find.byType(AppShellScreen)),
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Payments'), findsWidgets);
      expect(find.text('Paid since May'), findsOneWidget);

      // Second back: returns to Home
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Habari, David'), findsOneWidget);
    });

    testWidgets('system back in Home closes Pay Rent flow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(unlockedApp());
      await tester.pumpAndSettle();

      // Open Pay Rent
      await tester.tap(find.text('Pay rent'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pay_rent_flow_view')), findsOneWidget);

      // System back closes Pay Rent
      final navigator = Navigator.of(
        tester.element(find.byType(AppShellScreen)),
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Habari, David'), findsOneWidget);
      expect(find.byKey(const ValueKey('pay_rent_flow_view')), findsNothing);
    });

    testWidgets('system back in Repairs closes New Request form', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(unlockedApp());
      await tester.pumpAndSettle();

      // Open Repairs
      await tester.tap(find.text('Repairs').last);
      await tester.pumpAndSettle();

      // Open New Request
      await tester.tap(find.text('New request'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('report_repair_form_view')),
        findsOneWidget,
      );

      // System back closes New Request
      final navigator = Navigator.of(
        tester.element(find.byType(AppShellScreen)),
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('report_repair_form_view')),
        findsNothing,
      );
      expect(find.text('Socket in bedroom sparks'), findsOneWidget);

      // Second back returns to Home
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Habari, David'), findsOneWidget);
    });
  });
}
