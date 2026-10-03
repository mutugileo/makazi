import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/repairs/presentation/screens/repairs_screen.dart';

void main() {
  testWidgets(
    'RepairsScreen opens Report a repair form and handles submission',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RepairsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repairs'), findsOneWidget);
      expect(find.text('New request'), findsOneWidget);
      expect(find.text('Socket in bedroom sparks'), findsOneWidget);

      await tester.tap(find.text('New request'));
      await tester.pumpAndSettle();

      expect(find.text('Report a repair'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Electrical'), findsOneWidget);
      expect(find.text('Carpentry'), findsOneWidget);
      expect(find.text('Appliance'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
      expect(find.text('Submit request'), findsOneWidget);

      final backBtn = find.byIcon(Icons.chevron_left_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Report a repair'), findsNothing);
      expect(find.text('Repairs'), findsOneWidget);
    },
  );
}
