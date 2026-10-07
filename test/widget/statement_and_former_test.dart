import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/core/billing/billing_engine.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/navigation/presentation/state/navigation_providers.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Signed in and unlocked as the tenant with this phone (+254…).
ProviderScope _appAs(String phone) => ProviderScope(
  overrides: [authProvider.overrideWith(() => _SignedInAs(phone))],
  child: const PropMgtApp(),
);

class _SignedInAs extends AuthNotifier {
  _SignedInAs(this.phone) : super(initialStage: AuthStage.unlocked);
  final String phone;

  @override
  build() => super.build().copyWith(phone: phone);
}

void main() {
  testWidgets('statement totals match the bills and payments', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_appAs('+254733605118'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final account = container.read(tenantAccountProvider);
    final billed = account.bills.fold(0, (sum, b) => sum + b.newCharges);

    container.read(navigationProvider.notifier).navigateToPayments();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open_statement')));
    await tester.pumpAndSettle();

    expect(find.text('Statement'), findsOneWidget);
    expect(find.text('HarborRidge Limited'), findsOneWidget);
    expect(find.text(formatKes(billed)), findsOneWidget);
    expect(find.text(formatKes(account.totalPaid)), findsOneWidget);
    expect(find.text(formatKes(account.balance)), findsOneWidget);
  });

  testWidgets('a former tenant is read-only', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_appAs('+254720671093'));
    await tester.pumpAndSettle();

    expect(find.text('Habari, Joseph'), findsOneWidget);
    expect(find.text('Moved out'), findsOneWidget);
    expect(find.text('Records until 28 Feb 2027'), findsOneWidget);
    expect(find.text('Nothing due'), findsOneWidget);
    expect(find.text('Final bill'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(navigationProvider.notifier).navigateToRepairs();
    await tester.pumpAndSettle();
    expect(find.text('New request'), findsNothing);
  });
}
