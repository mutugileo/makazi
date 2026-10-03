import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/features/root/presentation/widgets/root_destination_view.dart';

void main() {
  testWidgets('RootScreen renders app title and initial overview destination', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PropMgtApp()));
    await tester.pumpAndSettle();

    expect(find.text('EstatePulse'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
    expect(find.byType(RootDestinationView), findsOneWidget);
  });

  testWidgets('RootScreen switches destination on navigation bar tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PropMgtApp()));
    await tester.pumpAndSettle();

    final propertiesTab = find.text('Properties');
    expect(propertiesTab, findsWidgets);

    await tester.tap(propertiesTab.last);
    await tester.pumpAndSettle();

    expect(
      find.text('Manage buildings, multi-family units, and vacant spaces'),
      findsOneWidget,
    );
  });
}
